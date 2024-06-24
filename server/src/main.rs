use std::{
    collections::{HashMap, HashSet},
    convert::Infallible,
    fmt::Debug,
    net::TcpStream,
    sync::{
        atomic::AtomicBool,
        mpsc::{channel, Receiver, Sender},
    },
    thread,
    time::Duration,
};

use rand::random;
use serde_json::json;
use uuid::Uuid;
use websocket::{
    sync::{Client, Reader, Writer},
    OwnedMessage,
};

fn main() {
    let mut server = websocket::sync::Server::bind("0.0.0.0:6996").unwrap();

    let (msg_sx, msg_rx) = channel();
    thread::spawn(move || main_loop(msg_rx));

    let ping_sx = msg_sx.clone();
    thread::spawn(move || ping_loop(ping_sx));

    while let Ok(conn) = server.accept() {
        let addr = conn.origin().map(str::to_string);
        let Ok(client) = conn.accept() else {
            eprintln!("Failed to accept client from conn: {:?}", addr);
            continue;
        };
        let msg_sx = msg_sx.clone();
        thread::spawn(move || client_loop(msg_sx, client));
    }
}
#[derive(Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Hash)]
struct ClientID(Uuid);

enum SocketMsg {
    ClientConnected(ClientID, Writer<TcpStream>),
    ClientDisconnected(ClientID),
    Pingall(Vec<u8>),
    ConfirmPong(Vec<u8>),
    ClientPong(ClientID, Vec<u8>),
    CreateLobby(ClientID),
    UserAdd(ClientID, u16, String),
}

static PING_SLEEP: AtomicBool = AtomicBool::new(false);

struct Lobby {
    devices: Vec<ClientID>,
    users: Vec<String>,
}

fn main_loop(msg_rx: Receiver<SocketMsg>) {
    let mut clients: HashMap<ClientID, Writer<TcpStream>> = HashMap::new();

    // PING/PONG
    let mut pong_clients: HashMap<ClientID, Vec<u8>> = HashMap::new();
    let mut allow_pongs = HashSet::new();

    let mut lobbies = HashMap::<u16, Lobby>::new();

    loop {
        let msg = msg_rx.recv().unwrap();

        println!("Main recv: {msg:#?}");
        match msg {
            SocketMsg::CreateLobby(client_id) => {
                let lobby_id = loop {
                    let lobby_id = random::<u16>();
                    if !lobbies.contains_key(&lobby_id) {
                        break lobby_id;
                    }
                };
                lobbies.insert(
                    lobby_id,
                    Lobby {
                        devices: vec![client_id],
                        users: vec![],
                    },
                );

                let Some(client) = clients.get_mut(&client_id) else {
                    clients.remove(&client_id);
                    lobbies.remove(&lobby_id);
                    continue;
                };

                let response = json!({"req": "LobbyCreated", "data": lobby_id});

                if let Err(_) = client.send_message(&OwnedMessage::Text(response.to_string())) {
                    clients.remove(&client_id);
                    lobbies.remove(&lobby_id);
                }
            }
            SocketMsg::UserAdd(_, lobby_id, username) => {
                //ClientID is ignored for now, when device names are implemented it will be needed

                let Some(lobby) = lobbies.get_mut(&lobby_id) else {
                    eprintln!("Tried to add user {username} to invalid lobby {lobby_id}");
                    continue;
                };
                lobby.users.push(username.clone());

                for client_id in &lobby.devices {
                    let Some(client) = clients.get_mut(client_id) else {
                        eprintln!("Client {client_id:?} no longer exists");
                        continue;
                    };
                    let msg = json!({"req": "UserAdd", "data": {"name": username, "device": "somewhere"}});

                    if let Err(_) = client.send_message(&OwnedMessage::Text(msg.to_string())) {
                        clients.remove(client_id);
                    }
                }
            }

            SocketMsg::ClientConnected(client_id, writer) => {
                clients.insert(client_id, writer);
            }
            SocketMsg::ClientDisconnected(client_id) => {
                clients.remove(&client_id);
            }

            // -- PING/PONG testing if connecions are still alive.
            SocketMsg::Pingall(pingdata) => {
                pong_clients.clear();
                allow_pongs.clear();

                clients.retain(|client_id, writer| {
                    allow_pongs.insert(*client_id);
                    writer
                        .send_message(&OwnedMessage::Ping(pingdata.clone()))
                        .is_ok()
                });
            }
            SocketMsg::ConfirmPong(pongdata) => {
                clients.retain(|k, _| {
                    !allow_pongs.contains(k)
                        || match pong_clients.get(k) {
                            Some(client_pongdata) => *client_pongdata == pongdata,
                            None => false,
                        }
                });
            }
            SocketMsg::ClientPong(client_id, pongdata) => {
                pong_clients.insert(client_id, pongdata);
            }
        }

        PING_SLEEP.store(clients.is_empty(), std::sync::atomic::Ordering::SeqCst);
    }
}

fn client_loop(mut msg_sx: Sender<SocketMsg>, mut client: Client<TcpStream>) {
    let client_id = ClientID(match client.recv_message().unwrap() {
        websocket::OwnedMessage::Text(client_id_str) => {
            Uuid::parse_str(&client_id_str).expect("Received invalid device_id in initialazation")
        }
        invalid_msg => panic!("Received invalid msg: {invalid_msg:#?} in initialzation"),
    });

    let (client_read, client_write) = client.split().unwrap();

    msg_sx
        .send(SocketMsg::ClientConnected(client_id, client_write))
        .unwrap();

    if let Err(err) = inner_client_loop(client_id, &mut msg_sx, client_read) {
        eprintln!("Client error: {err:?}");
    };

    msg_sx
        .send(SocketMsg::ClientDisconnected(client_id))
        .unwrap();
}

fn inner_client_loop(
    client_id: ClientID,
    msg_sx: &mut Sender<SocketMsg>,
    mut client: Reader<TcpStream>,
) -> anyhow::Result<Infallible> {
    #[derive(Debug, serde::Deserialize)]
    enum ClientMsg {
        CreateLobby,
        UserAdd(u16, String),
    }

    loop {
        let msg = client.recv_message()?;
        match msg {
            websocket::OwnedMessage::Binary(_) => todo!(),
            websocket::OwnedMessage::Close(_) => todo!(),
            websocket::OwnedMessage::Ping(_) => todo!(),
            websocket::OwnedMessage::Pong(pongdata) => {
                msg_sx.send(SocketMsg::ClientPong(client_id, pongdata))?
            }
            websocket::OwnedMessage::Text(jsonmsg) => {
                println!("ClientMsg: {jsonmsg}");
                let Ok(msg): Result<ClientMsg, _> = serde_json::from_str(&jsonmsg) else {
                    eprintln!("Client sent invalid msg: {jsonmsg}");
                    continue;
                };
                match msg {
                    ClientMsg::CreateLobby => {
                        msg_sx.send(SocketMsg::CreateLobby(client_id))?;
                    }
                    ClientMsg::UserAdd(lobby_id, username) => {
                        msg_sx.send(SocketMsg::UserAdd(client_id, lobby_id, username))?;
                    }
                }
            }
        }
    }
}

fn ping_loop(msg_sx: Sender<SocketMsg>) {
    loop {
        if PING_SLEEP.load(std::sync::atomic::Ordering::Relaxed) {
            thread::sleep(Duration::from_secs(10));
        } else {
            let confirm_data: Vec<u8> = Uuid::new_v4().to_string().into();
            thread::sleep(Duration::from_secs(5));
            msg_sx
                .send(SocketMsg::Pingall(confirm_data.clone()))
                .unwrap();

            thread::sleep(Duration::from_secs(5));
            msg_sx.send(SocketMsg::ConfirmPong(confirm_data)).unwrap();
        }
    }
}

impl Debug for SocketMsg {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::ClientConnected(arg0, _arg1) => {
                f.debug_tuple("ClientConnected").field(arg0).finish()
            }
            Self::ClientDisconnected(arg0) => {
                f.debug_tuple("ClientDisconnected").field(arg0).finish()
            }
            SocketMsg::Pingall(_) => f.debug_tuple("PingAll").finish(),
            SocketMsg::ConfirmPong(_) => f.debug_tuple("ConfirmPong").finish(),
            SocketMsg::ClientPong(arg0, _) => f.debug_tuple("ClientPong").field(arg0).finish(),
            SocketMsg::CreateLobby(arg0) => f.debug_tuple("CreateLobby").field(arg0).finish(),
            SocketMsg::UserAdd(arg0, arg1, arg2) => f
                .debug_tuple("UserAdd")
                .field(arg0)
                .field(arg1)
                .field(arg2)
                .finish(),
        }
    }
}
