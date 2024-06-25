use std::{convert::Infallible, net::TcpStream, sync::mpsc::Sender};

use uuid::Uuid;
use websocket::sync::{Client, Reader};

use crate::{writer::WriterEvent, ClientID, LobbyID, MainEvent};

pub fn client_loop(
    main_sx: Sender<MainEvent>,
    mut client: Client<TcpStream>,
    writer_sx: Sender<WriterEvent>,
) {
    let client_id = ClientID(match client.recv_message().unwrap() {
        websocket::OwnedMessage::Text(client_id_str) => {
            Uuid::parse_str(&client_id_str).expect("Received invalid device_id in initialazation")
        }
        invalid_msg => panic!("Received invalid msg: {invalid_msg:#?} in initialzation"),
    });

    let (client_read, client_write) = client.split().unwrap();

    writer_sx
        .send(WriterEvent::ClientConnected(client_id, client_write))
        .unwrap();

    if let Err(err) = inner_client_loop(client_id, main_sx, client_read, &writer_sx) {
        eprintln!("Client error: {err:?}");
    };

    writer_sx
        .send(WriterEvent::ClientDisconnected(client_id))
        .unwrap();
}

pub fn inner_client_loop(
    client_id: ClientID,
    main_sx: Sender<MainEvent>,
    mut client: Reader<TcpStream>,
    writer_sx: &Sender<WriterEvent>,
) -> anyhow::Result<Infallible> {
    #[derive(Debug, serde::Deserialize)]
    enum ClientMsg {
        CreateLobby,
        UserAdd(LobbyID, String),
    }

    loop {
        let msg = client.recv_message()?;
        match msg {
            websocket::OwnedMessage::Binary(_) => todo!(),
            websocket::OwnedMessage::Close(_) => todo!(),
            websocket::OwnedMessage::Ping(_) => todo!(),
            websocket::OwnedMessage::Pong(pongdata) => {
                writer_sx.send(WriterEvent::ClientPong(client_id, pongdata))?
            }
            websocket::OwnedMessage::Text(jsonmsg) => {
                println!("ClientMsg: {jsonmsg}");
                let Ok(msg): Result<ClientMsg, _> = serde_json::from_str(&jsonmsg) else {
                    eprintln!("Client sent invalid msg: {jsonmsg}");
                    continue;
                };
                match msg {
                    ClientMsg::CreateLobby => {
                        main_sx.send(MainEvent::CreateLobby(client_id))?;
                    }
                    ClientMsg::UserAdd(lobby_id, username) => {
                        main_sx.send(MainEvent::UserAdd(client_id, lobby_id, username))?;
                    }
                }
            }
        }
    }
}
