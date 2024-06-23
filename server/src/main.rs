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
}

static PING_SLEEP: AtomicBool = AtomicBool::new(false);

fn main_loop(msg_rx: Receiver<SocketMsg>) {
    let mut clients = HashMap::new();

    // PING/PONG
    let mut pong_clients: HashMap<ClientID, Vec<u8>> = HashMap::new();
    let mut allow_pongs = HashSet::new();

    loop {
        let msg = msg_rx.recv().unwrap();

        println!("Main recv: {msg:#?}");
        match msg {
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
    loop {
        let msg = client.recv_message()?;
        match msg {
            websocket::OwnedMessage::Text(_) => todo!(),
            websocket::OwnedMessage::Binary(_) => todo!(),
            websocket::OwnedMessage::Close(_) => todo!(),
            websocket::OwnedMessage::Ping(_) => todo!(),
            websocket::OwnedMessage::Pong(pongdata) => {
                msg_sx.send(SocketMsg::ClientPong(client_id, pongdata))?
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
        }
    }
}
