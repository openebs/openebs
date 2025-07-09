use nu_ansi_term::Color::{Cyan, Red};

/// Print info on console.
pub fn info(message: &str, data: Option<&str>) {
    if let Some(data) = data {
        println!("{}: {}", Cyan.paint(message), Cyan.paint(data));
        return;
    }
    println!("{}", Cyan.paint(message));
}

/// Print error on console.
pub fn error(message: &str, data: &str) {
    eprintln!("{}: {} ", Red.paint(message), Red.paint(data));
}
