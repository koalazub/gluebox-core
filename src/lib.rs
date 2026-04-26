pub mod connector;
pub mod power;
pub mod registry;

pub use connector::{Connector, ConnectorStatus};
pub use power::{PowerConfig, PowerManager, PowerState};
pub use registry::ConnectorRegistry;
