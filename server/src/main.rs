use std::{
    collections::{HashMap, HashSet},
    fmt::Debug,
    sync::mpsc::{channel, Receiver, Sender},
    thread,
};

use client::client_loop;
use pinger::ping_loop;
use rand::random;
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use writer::{writer_loop, WriterEvent};

mod client;
mod pinger;
mod writer;

fn main() {
    let mut server = websocket::sync::Server::bind("0.0.0.0:6996").unwrap();
    let (main_sx, main_rx) = channel();
    let (writer_sx, response_rx) = channel();
    let main_writer_sx = writer_sx.clone();
    thread::spawn(move || main_loop(main_rx, main_writer_sx));
    let writer_main_sx = main_sx.clone();
    thread::spawn(move || writer_loop(response_rx, writer_main_sx));

    let ping_writer_sx = writer_sx.clone();
    thread::spawn(move || ping_loop(ping_writer_sx));

    while let Ok(conn) = server.accept() {
        let addr = conn.origin().map(str::to_string);
        let Ok(client) = conn.accept() else {
            eprintln!("Failed to accept client from conn: {:?}", addr);
            continue;
        };
        let msg_sx = main_sx.clone();
        let writer_sx = writer_sx.clone();
        thread::spawn(move || client_loop(msg_sx, client, writer_sx));
    }
}
#[derive(Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Hash, Serialize, Deserialize)]
struct ClientID(Uuid);

#[derive(Debug, Clone, Copy, Eq, PartialEq, Hash, serde::Serialize, serde::Deserialize)]
struct LobbyID(u16);

#[derive(Debug)]
enum MainEvent {
    ClientDisconnected(ClientID),
    CreateLobby(ClientID),
    UserAdd(ClientID, LobbyID, String),
    JoinLobby(ClientID, LobbyID),
    ExitLobby(ClientID, LobbyID),
    StartGame(ClientID, LobbyID),
    PassTurn(ClientID, LobbyID),
}

#[derive(Debug, serde::Serialize)]
enum Response {
    LobbyCreated(LobbyID),
    UserAdd {
        lobby_id: LobbyID,
        username: String,
        client_id: ClientID,
    },
    UserRemove {
        lobby_id: LobbyID,
        username: String,
    },
    JoinLobby {
        success: bool,
        users: Vec<(String, ClientID)>,
    },
    StartGame {
        lobby_id: LobbyID,
    },
    SetTurn((String, ClientID)),
    Error(String),
}

struct Lobby {
    devices: HashSet<ClientID>,
    users: Vec<(String, ClientID)>,
    game: Option<Game>,
}

struct Game {
    current_turn: (String, ClientID),
}

fn main_loop(msg_rx: Receiver<MainEvent>, response_sx: Sender<WriterEvent>) {
    let send = |response: Response, recv: Vec<ClientID>| {
        response_sx
            .send(WriterEvent::MsgSend(response, recv))
            .unwrap();
    };

    let mut lobbies = HashMap::<LobbyID, Lobby>::new();

    loop {
        let msg = msg_rx.recv().unwrap();

        println!("Main recv: {msg:#?}");
        match msg {
            MainEvent::CreateLobby(client_id) => {
                let lobby_id = LobbyID(loop {
                    let lobby_id = random::<u16>();
                    if !lobbies.contains_key(&LobbyID(lobby_id)) && lobby_id > 999 {
                        break lobby_id;
                    }
                });
                lobbies.insert(
                    lobby_id,
                    Lobby {
                        devices: HashSet::from([client_id]),
                        users: vec![],
                        game: None,
                    },
                );

                send(Response::LobbyCreated(lobby_id), vec![client_id]);
            }
            MainEvent::UserAdd(client_id, lobby_id, username) => {
                let Some(lobby) = lobbies.get_mut(&lobby_id) else {
                    eprintln!("Tried to add user {username} to invalid lobby {lobby_id:?}");
                    continue;
                };
                lobby.users.push((username.clone(), client_id));
                send(
                    Response::UserAdd {
                        lobby_id,
                        username,
                        client_id,
                    },
                    lobby.devices.clone().into_iter().collect(),
                );
            }
            MainEvent::JoinLobby(client_id, lobby_id) => {
                let Some(lobby) = lobbies.get_mut(&lobby_id) else {
                    send(
                        Response::JoinLobby {
                            success: false,
                            users: vec![],
                        },
                        vec![client_id],
                    );
                    continue;
                };
                lobby.devices.insert(client_id);
                send(
                    Response::JoinLobby {
                        success: true,
                        users: lobby.users.clone(),
                    },
                    vec![client_id],
                );
            }
            MainEvent::ExitLobby(client_id, lobby_id) => {
                if let Some(lobby) = lobbies.get_mut(&lobby_id) {
                    lobby.devices.remove(&client_id);

                    for (username, _) in lobby.users.iter().filter(|(_, c)| *c == client_id) {
                        send(
                            Response::UserRemove {
                                lobby_id,
                                username: username.clone(),
                            },
                            lobby.devices.clone().into_iter().collect(),
                        );
                    }
                    lobby.users.retain(|(_, c)| *c != client_id);
                }
            }
            MainEvent::ClientDisconnected(client_id) => {
                for (lobby_id, lobby) in &mut lobbies {
                    if let Some(_) = lobby.devices.take(&client_id) {
                        for (username, _) in lobby.users.iter().filter(|(_, c)| *c == client_id) {
                            send(
                                Response::UserRemove {
                                    lobby_id: *lobby_id,
                                    username: username.clone(),
                                },
                                lobby.devices.clone().into_iter().collect(),
                            );
                        }
                        lobby.users.retain(|(_, c)| *c != client_id);
                    }
                }
                //Clean empty lobbies
                lobbies.retain(|_, l| l.devices.len() > 0);
            }
            MainEvent::StartGame(client_id, lobby_id) => {
                let Some(lobby) = lobbies.get_mut(&lobby_id) else {
                    eprintln!("Attempted stargin invalid lobby {lobby_id:?}");
                    continue;
                };

                if !lobby.devices.contains(&client_id) {
                    eprintln!("{client_id:?} attempted to start nonjoined lobby");
                    send(
                        Response::Error("Not a part of lobby".into()),
                        vec![client_id],
                    );
                    continue;
                }
                let Some(first_user) = lobby.users.first() else {
                    send(Response::Error("Lobby is empty".into()), vec![client_id]);
                    continue;
                };
                lobby.game = Some(Game {
                    current_turn: first_user.to_owned(),
                });

                send(
                    Response::StartGame { lobby_id },
                    lobby.devices.clone().into_iter().collect(),
                );
            }
            MainEvent::PassTurn(client_id, lobby_id) => {
                let Some(lobby) = lobbies.get_mut(&lobby_id) else {
                    send(Response::Error("Invalid lobbyID".into()), vec![client_id]);
                    continue;
                };

                let Some(game) = &mut lobby.game else {
                    send(Response::Error("Game not started".into()), vec![client_id]);
                    continue;
                };
                let Some(position) = lobby.users.iter().position(|u| *u == game.current_turn)
                else {
                    send(
                        Response::Error("Server cannot calculate next user. Resetting".into()),
                        lobby.devices.clone().into_iter().collect(),
                    );
                    continue;
                };
                let new_position = (position + 1) % lobby.users.len();
                game.current_turn = lobby.users[new_position].clone();
                send(
                    Response::SetTurn(game.current_turn.clone()),
                    lobby.devices.clone().into_iter().collect(),
                );
            }
        }
    }
}
