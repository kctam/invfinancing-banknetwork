# Demonstration of Invoice Financing on a Bank Network

Invoice Financing demo on a Bank Network using Hyperledger Fabric

The Bank Network is composed of two banks (organizations), Alpha and Beta. Each bank has two peer nodes.

## Step 0: prepare a Fabric Node
Following the steps for a fabric node, which includes the prerequisite, fabric-samples and hyperledger fabric images.
```
cd fabric-samples
```

## Step 1: bring up everything for demonstration
```
cd invfinancing-banknetwork
./starteverything.sh
```
## Step 2: install the required SDK
```
npm install
```

## Step 3: Enrol user-alpha and user-beta in wallet
```
node enrollAdmin-alpha.js
node registerUser-alpha.js

node enrollAdmin-beta.js
node registerUser-beta.js

ls wallet
```

## Step 4: Perform client applications.
Substitute *bank* with **alpha** or **beta** to reflect which bank runs the client application.

Initialize a new invoice for a company: `node initInv-bank.js <company> <invno> <invamount>`. For example,
```
node initInv-alpha.js Alice inv-bob001 10000
```

Query an existing invoice: `node queryInv-bank.js <company> <invno>`. For example,
```
node queryInv-alpha.js Alice inv-bob001
```

Request loan on an existing invoice: `node requestLoan-bank.js <company> <invno> <loanamt>`. For example,
```
node requestLoan-alpha.js Alice inv-bob001 7000
```

You can try any combination of command, simulating query from other bank, or company applies amount exceeding the invoice amount, etc.


## Step 5: Clean up
```
./teardowneverything.sh
```

**End**
