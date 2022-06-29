// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
    The campaign Factory contract makes sure we are not being charged for each campaign created (aka contract deployed)
    and the user (campaign owner/creator) does NOT have access to the source code to modify it (for example change the
    contribute function and send each contribution to his own wallet)!
*/
contract CampaignFactory {
    //Array of deployed campaigns
    address[] public deployedCampaigns;

    /**
    *   Creates a new instance of the campaign contract and adds that to our array of campaigns
    */
    function createCampaign(uint minimum, uint goal) public {
        address newCampaign = address(new Campaign(minimum, msg.sender, goal));         //Instanciate the Campaign contract
        deployedCampaigns.push(newCampaign);                                            //Add newly created campaign to our array of campaigns
    }

    /**
    *   Returns the array of deployed campaigns
    */
    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    //Use of a struct to model a request. This is a definitition NOT an instance of a variable
    struct Request {
        string description;                     //Description of why the request is created
        uint value;                             //Value is the amount of money needed complete said request
        address recipient;                      //Address of who will receive the money
        bool complete;                          //Flag to see if request has been completed
        uint approvalsCount;                    //Amount of backers who approved this request
        mapping(address => bool) approvals;     //List of people who approved said request
    }

    //Use of struct to model the different pledge categories
    struct PledgeCategory {
        string description;                     //Description of the pledge plus reward
        uint value;                             //Cost for entering in the pledge
        uint maxBrackers;                       //Maximum number of people who can join this pledge
        uint backersCount;                      //Number of backers within this pledge
        mapping(address => bool) pledgeBrackers;      //Mapping of all backers who are in this pledge category
    }

    address public contractOwner;               //Campain Creator
    uint public minimumContribution;            // Minimum contribution required to enter
    uint public campaignGoal;                   // Minimum amount the campaign needs to be successfully funded
    uint256 public expireDate;                  //All campaigns have a limited lifespan ususally 1 - 2 months
    bool private expired;                       //Flag for contract to see if it was successffully funded or not
    uint public currentFunding;                 // The current amount entered into a campaign

    mapping(address => bool) public backers;    //A mapping of all the backers
    uint public backersCount;                   //The count of all backers (since we are not able to get that with a mapping)

    mapping (uint => PledgeCategory) public pledgeCategory;     // A mapping of all categories of pledges made by the owner
    uint public pledgesCount;                   //The count of all categories of different pledges (since we are not able to get that with a mapping)

    mapping (uint => Request) public requests;  //A mapping of all requests made
    uint public requestsCount;                  //The count of all requests (since we are not able to get that with a mapping)

    // Modifier which restricts certain actions to only the owner of a campaign
    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    //Modifier which will restrict actions if the campaign expired by either not being funded or the owner cancelled
    modifier notExpired() {
        require(expired != true);
        _;
    }

    // Modifier which restricts actions if the sender is not a backer of the campaign
    modifier onlyBacker() {
        require(backers[msg.sender]);
        _;
    }

    /*
    *   When creating a contract we set the owner of the contract and the min contribution
    */
    constructor(uint minimum, address creator, uint goal) {
        contractOwner = creator;                // Set owner
        minimumContribution = minimum;          //Set minimum contribution to that passed through
        campaignGoal = goal;                    //Set the campaign goal to bring said product to life
        expireDate = block.timestamp + 60 days; //Set the lifespan of the contract to be 2 months
        expired = false;                        //Set expired flag
    }

    /*
    *   Function that accepts a contribution (hence the 'payable' keyword) if certain criteria are passed
    */
    function contribute(uint pledgeIndex) public payable {
        require(msg.value > minimumContribution);                       //Money received must be more than the minimum contribution which we set when we created the contract!
        PledgeCategory storage pledge = pledgeCategory[pledgeIndex];    //Retrive the pledge category the backer wants to join //TODO: Should we check to see if pledge exist???
        require(msg.value > pledge.value);                              //The potential backer must have sent enough ether to join said pledge category
        require(pledge.backersCount < pledge.maxBrackers);              //There should be available spaces in said pledge category
        require(!pledge.pledgeBrackers[msg.sender]);                           //The address must not be a backer already. (Technically this needs more work cause people can update pledges and so on so for the time we are assuming you can only join 1 pledge and that is final)
        pledge.pledgeBrackers[msg.sender] = true;                              //Add the new contributor into said pledge
        pledge.backersCount++;                                          //Increment the number of backers in said pledge
        backers[msg.sender] = true;                                     //If backers passes the above check we add him to the contributors array
        backersCount++;                                                 //Increment the number of total contributors
        currentFunding += msg.value;                                    //Add the contribution to the total for said campaign
    }

    /*
    *   Function that create a request for a campaign. Only the contract owner can call this
    *   to avoid people creating fraudulent requests and send them money or something!
    */
    function createRequest(string memory description, uint value, address recipient) public onlyOwner {
        Request storage newRequest = requests[requestsCount++];

        newRequest.description = description;
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.complete = false;
        newRequest.approvalsCount = 0;
    }

    /*
    *   Function that creates a pledge category. Once again only the contract owner can call it by applying the modifier created 'onlyOwner'
    */
    function createPledgeCategory(string memory description, uint value, uint maxBrackers) public onlyOwner {
        PledgeCategory storage newPledgeCategory = pledgeCategory[pledgesCount++];

        newPledgeCategory.description = description;
        newPledgeCategory.value = value;
        newPledgeCategory.maxBrackers = maxBrackers;
        newPledgeCategory.backersCount = 0;
    }

    /*
    *   Function that contributors/backers can call to approve specific request
    */
    function approveRequest(uint requestIndex) public onlyBacker {
        Request storage request = requests[requestIndex];               //Find the request using the index we pass to the function call

        require(!request.approvals[msg.sender]);                        //Backer/contributor must not have already approved it since you can only approve a request once
        request.approvals[msg.sender] = true;                           //Add the backer into the mapping of people who approve of said request to go through
        request.approvalsCount++;                                       //Increment the total amount of people who approved this request
    }

    /*
    *   Function that checks if a request has enough approvals and if so sends the money
    */
    function finalizeRequest(uint index) public onlyOwner {
        Request storage request = requests[index];                      //Find the request using the index we pass to the function call

        require(!request.complete);                                     //Make sure request is not done. We don't want to send the money twice!
        require(request.approvalsCount > (backersCount / 2));           //Make sure at least more than 50% of backers approve of the request

        payable(request.recipient).transfer(request.value);             //Send the money
        request.complete = true;                                        //Mark request as complete
    }

    /**
     *  Sometimes campaigns cannot go through for a number of reasons. If that is the case then
     *  the creator of the campaign can cancel it and therefor return the pledges received so far
     */
    function cancelCampaign() public onlyOwner notExpired {
        expired = true;                                                 //Firstly we set the flag to true
        returnPledges();                                                //Now we need to return all the funds we received
    }

    // Return the pledges of all backers
    function returnPledges() public payable onlyOwner {

    }

    /**
    *   Function to check if the campaign goal is reached
    */
    function checkGoalReached() view public returns (bool reached) {
        reached = false;
        if (currentFunding >= campaignGoal) {
            reached = true;
        }
        return reached;
    }
}
