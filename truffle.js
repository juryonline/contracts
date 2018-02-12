module.exports = {
    networks: {
        ropsten: {
            host: '144.76.8.56/testnet',
            port: 80,
            network_id: "3", // ropsten
            from: "0xc6e74d537e2b8de41cf4a682ab7d9a1f8b91f8e1", //sender address
            gas: 4508000 
        },
        local: {
            host: "localhost",
            port: 8545,
            network_id: "*", // Match any network id
            from: "0x4C67EB86d70354731f11981aeE91d969e3823c39", //sender address
            gas: 4500000
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
