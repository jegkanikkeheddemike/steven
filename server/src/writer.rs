use std::{
    collections::HashMap,
    net::TcpStream,
    sync::mpsc::{Receiver, Sender},
};

use websocket::{sync::Writer, OwnedMessage};

use crate::{ClientID, MainEvent, Response};

pub enum WriterEvent {
    ClientConnected(ClientID, Writer<TcpStream>),
    ClientDisconnected(ClientID),
    MsgSend(Response, Vec<ClientID>),
    PingAll(Vec<u8>),
    ConfirmPong(Vec<u8>),
    ClientPong(ClientID, Vec<u8>),
}

pub fn writer_loop(response_rx: Receiver<WriterEvent>, main_sx: Sender<MainEvent>) {
    let mut clients: _ = HashMap::<ClientID, Writer<TcpStream>>::new();

    // -- PING/PONG
    let mut client_pongs: HashMap<ClientID, Vec<u8>> = HashMap::new();
    let mut pinged: Vec<ClientID> = vec![];

    loop {
        match response_rx.recv().unwrap() {
            WriterEvent::MsgSend(response, resp_clients) => {
                println!("Writing: {response:#?} to {resp_clients:?}");
                let response_msg = OwnedMessage::Text(serde_json::to_string(&response).unwrap());

                for client_id in resp_clients {
                    let Some(writer) = clients.get_mut(&client_id) else {
                        eprintln!("Attempting to write to deleted client {client_id:?}");
                        continue;
                    };
                    if let Err(_) = writer.send_message(&response_msg) {
                        clients.remove(&client_id);
                        main_sx
                            .send(MainEvent::ClientDisconnected(client_id))
                            .unwrap();
                    }
                }
            }
            WriterEvent::ClientConnected(client_id, writer) => {
                clients.insert(client_id, writer);
            }
            WriterEvent::ClientDisconnected(client_id) => {
                clients.remove(&client_id);
                main_sx
                    .send(MainEvent::ClientDisconnected(client_id))
                    .unwrap();
            }
            WriterEvent::ClientPong(client_id, pong) => {
                client_pongs.insert(client_id, pong);
            }
            WriterEvent::PingAll(ping) => {
                let message = OwnedMessage::Ping(ping);
                let mut failed = vec![];
                for (client_id, writer) in &mut clients {
                    if let Ok(_) = writer.send_message(&message) {
                        pinged.push(*client_id);
                    } else {
                        failed.push(*client_id);
                    }
                }
                for client_id in failed {
                    clients.remove(&client_id);
                    main_sx
                        .send(MainEvent::ClientDisconnected(client_id))
                        .unwrap();
                }
            }
            WriterEvent::ConfirmPong(confirm_pong) => {
                for client_id in &pinged {
                    let Some(pong) = client_pongs.get(client_id) else {
                        clients.remove(client_id);
                        main_sx
                            .send(MainEvent::ClientDisconnected(*client_id))
                            .unwrap();
                        continue;
                    };
                    if *pong != confirm_pong {
                        clients.remove(client_id);
                        main_sx
                            .send(MainEvent::ClientDisconnected(*client_id))
                            .unwrap();
                    }
                }
                pinged.clear();
            }
        }
    }
}
