// Low memory profile - reduces memory allocation across components.
// Include this at the END of your configuration to override default memory
// settings with lower values suitable for memory-constrained environments.
//
// Usage: {"name": "memory-profile-low", "parameters": {}}
//
// Note: This trades some performance headroom for reduced memory usage.
// Monitor for OOM errors under heavy load.

{

    // Override Pulsar stack memory settings
    "pulsar" +: {

        // Zookeeper: 512M -> 300M
        "zk-memory-limit":: "300M",
        "zk-memory-reservation":: "200M",
        "zk-heap":: "128m",
        "zk-direct-memory":: "64m",

        // Bookie: 1024M -> 600M
        "bookie-memory-limit":: "600M",
        "bookie-memory-reservation":: "400M",
        "bookie-heap":: "128m",
        "bookie-direct-memory":: "128m",

        // Broker: 800M -> 512M
        "broker-memory-limit":: "512M",
        "broker-memory-reservation":: "400M",
        "broker-heap":: "192m",
        "broker-direct-memory":: "192m",

        // Pulsar-init: 256M -> 128M
        "init-memory-limit":: "128M",
        "init-memory-reservation":: "128M",
        "init-heap":: "64m",
        "init-direct-memory":: "64m",

    },

}
