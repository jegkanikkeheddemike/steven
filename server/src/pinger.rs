use std::{sync::mpsc::Sender, thread, time::Duration};

use uuid::Uuid;

use crate::writer::WriterEvent;
pub fn ping_loop(msg_sx: Sender<WriterEvent>) {
    loop {
        let confirm_data: Vec<u8> = Uuid::new_v4().to_string().into();
        thread::sleep(Duration::from_secs(5));
        msg_sx
            .send(WriterEvent::PingAll(confirm_data.clone()))
            .unwrap();

        thread::sleep(Duration::from_secs(5));
        msg_sx.send(WriterEvent::ConfirmPong(confirm_data)).unwrap();
    }
}
