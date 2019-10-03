/*
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { FileSystemWallet, Gateway, X509WalletMixin } = require('fabric-network');
const path = require('path');

const ccpPath = path.resolve(__dirname, 'bank-network', 'connection-beta.json');

async function main() {
    try {

        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = new FileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the user.
        const userExists = await wallet.exists('user-beta');
        if (userExists) {
            console.log('An identity for the user "user-beta" already exists in the wallet');
            return;
        }

        // Check to see if we've already enrolled the admin user.
        const adminExists = await wallet.exists('admin-beta');
        if (!adminExists) {
            console.log('An identity for the admin user "admin-beta" does not exist in the wallet');
            console.log('Run the enrollAdmin-beta.js application before retrying');
            return;
        }

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccpPath, { wallet, identity: 'admin-beta', discovery: { enabled: true, asLocalhost: true } });

        // Get the CA client object from the gateway for interacting with the CA.
        const ca = gateway.getClient().getCertificateAuthority();
        const adminIdentity = gateway.getCurrentIdentity();

        // Register the user, enroll the user, and import the new identity into the wallet.
        const secret = await ca.register({ affiliation: 'beta.department1', enrollmentID: 'user-beta', role: 'client' }, adminIdentity);
        const enrollment = await ca.enroll({ enrollmentID: 'user-beta', enrollmentSecret: secret });
        const userIdentity = X509WalletMixin.createIdentity('BetaMSP', enrollment.certificate, enrollment.key.toBytes());
        await wallet.import('user-beta', userIdentity);
        console.log('Successfully registered and enrolled admin user "user-beta" and imported it into the wallet');

    } catch (error) {
        console.error(`Failed to register user "user-beta": ${error}`);
        process.exit(1);
    }
}

main();
