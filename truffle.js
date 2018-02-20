module.exports = {
    networks: {
        local: {
            host: "localhost",
            port: 8545,
            network_id: "*", // Match any network id
            gas: 6500000
        },
        live: {
            network_id: 1,
            host: "localhost",
            port: 8546   // Different than the default below
        },
        test: {
            network_id: 1,
            host: "localhost",
            port: 8545,   // Different than the default below
            gas: 6500000 
        }
    }
};
