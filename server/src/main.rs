use std::{
    collections::HashMap,
    fmt::Debug,
    sync::mpsc::{channel, Receiver, Sender},
    thread,
};

use client::client_loop;
use pinger::ping_loop;
use rand::random;
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
#[derive(Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Hash)]
struct ClientID(Uuid);

#[derive(Debug, Clone, Copy, Eq, PartialEq, Hash, serde::Serialize, serde::Deserialize)]
struct LobbyID(u16);

#[derive(Debug)]
enum MainEvent {
    ClientDisconnected(ClientID),
    CreateLobby(ClientID),
    UserAdd(ClientID, LobbyID, String),
    JoinLobby(ClientID, LobbyID),
}

#[derive(Debug, serde::Serialize)]
enum Response {
    LobbyCreated(LobbyID),
    UserAdd {
        lobby_id: LobbyID,
        username: String,
    },
    UserRemove(LobbyID, String),
    JoinLobby {
        success: bool,
        usernames: Vec<String>,
    },
}

struct Lobby {
    devices: Vec<ClientID>,
    users: Vec<(String, ClientID)>,
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
                        devices: vec![client_id],
                        users: vec![],
                    },
                );

                send(Response::LobbyCreated(lobby_id), vec![client_id]);
            }
            MainEvent::UserAdd(client_id, lobby_id, username) => {
                //ClientID is ignored for now, when device names are implemented it will be needed

                let Some(lobby) = lobbies.get_mut(&lobby_id) else {
                    eprintln!("Tried to add user {username} to invalid lobby {lobby_id:?}");
                    continue;
                };
                lobby.users.push((username.clone(), client_id));
                send(
                    Response::UserAdd { lobby_id, username },
                    lobby.devices.clone(),
                );
            }
            MainEvent::ClientDisconnected(client_id) => {
                for (lobby_id, lobby) in &mut lobbies {
                    if let Some(position) = lobby.devices.iter().position(|c| *c == client_id) {
                        lobby.devices.remove(position);
                        for (username, _) in lobby.users.iter().filter(|(_, c)| *c == client_id) {
                            send(
                                Response::UserRemove(*lobby_id, username.clone()),
                                lobby.devices.clone(),
                            );
                        }
                        lobby.users.retain(|(_, c)| *c != client_id);
                    }
                }
            }
            MainEvent::JoinLobby(client_id, lobby_id) => {
                let Some(lobby) = lobbies.get_mut(&lobby_id) else {
                    send(
                        Response::JoinLobby {
                            success: false,
                            usernames: vec![],
                        },
                        vec![client_id],
                    );
                    continue;
                };
                lobby.devices.push(client_id);
                let usernames = lobby.users.iter().map(|(u, _)| u.to_owned()).collect();
                send(
                    Response::JoinLobby {
                        success: true,
                        usernames,
                    },
                    vec![client_id],
                );
            }
        }
    }
}
