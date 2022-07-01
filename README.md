# Web3-Kickstarter

## Pre-setup

Firstly you need to deploy the CampaignFactory contract and save the address into the ADDRESS.txt file (and in factory.js)
You will also need an INFURA account since that will be our web3 provider and the custom link you will receive needs to be added to web3.js and deploy.js (together with your mnemonic)
Lastly since there is no front-end to create a campaign from the browser you will need to go to Remix and load the deployed CampaignFactory contract and then using that create some dummy campaigns!

## Setup

Once all the above steps are done you should be able just launch the front-end but before you do that you probably need to install some packages:
**Make sure you are inside the project directory :D

### Install React, React-dom and Next.js
```
npm install next react react-dom
```

### Run the project
```
npm run dev
```
