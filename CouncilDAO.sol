// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import ERC721 from OpenZeppelin (Remix-compatible GitHub URL)
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";

/// @title MembershipNFT
/// @notice Simple ERC721 NFT used to grant DAO membership/voting rights
contract MembershipNFT is ERC721 {
    uint256 public nextTokenId;
    address public admin;

    /// @notice Set name/symbol and admin
    constructor() ERC721("DAO Membership NFT", "DAOM") {
        admin = msg.sender;
    }

    /// @notice Mint a membership NFT to to
    /// @dev Only callable by admin
    /// @param to Recipient address
    function mint(address to) external {
        require(msg.sender == admin, "MembershipNFT: caller is not admin");
        _mint(to, nextTokenId);
        nextTokenId++;
    }
}

/// @title NFTAccessDAO
/// @notice DAO where only NFT holders can propose and vote
contract NFTAccessDAO {
    /// @dev Represents a proposal in the DAO
    struct Proposal {
        string description;
        uint256 deadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    MembershipNFT public membershipNFT;
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    /// @notice Set the MembershipNFT contract address
    /// @param _nft Address of a deployed MembershipNFT
    constructor(address _nft) {
        membershipNFT = MembershipNFT(_nft);
    }

    /// @notice Create a new proposal
    /// @dev Only callable by NFT holders
    /// @param description Text describing the proposal
    function createProposal(string calldata description) external {
        require(
            membershipNFT.balanceOf(msg.sender) > 0,
            "NFTAccessDAO: must hold an NFT to propose"
        );
        proposalCount++;
        proposals[proposalCount] = Proposal({
            description: description,
            deadline: block.timestamp + 3 days,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
    }

    /// @notice Vote on a proposal
    /// @dev Only callable by NFT holders, one vote per NFT per proposal
    /// @param proposalId ID of the proposal
    /// @param support true = vote yes, false = vote no
    function vote(uint256 proposalId, bool support) external {
        require(
            membershipNFT.balanceOf(msg.sender) > 0,
            "NFTAccessDAO: must hold an NFT to vote"
        );
        Proposal storage prop = proposals[proposalId];
        require(block.timestamp < prop.deadline, "NFTAccessDAO: voting period over");
        require(!hasVoted[proposalId][msg.sender], "NFTAccessDAO: already voted");

        if (support) {
            prop.yesVotes += 1;
        } else {
            prop.noVotes += 1;
        }
        hasVoted[proposalId][msg.sender] = true;
    }

    /// @notice Execute a passed proposal
    /// @dev No on-chain action defined; mark executed to prevent re-execution
    /// @param proposalId ID of the proposal to execute
    function execute(uint256 proposalId) external {
        Proposal storage prop = proposals[proposalId];
        require(block.timestamp >= prop.deadline, "NFTAccessDAO: voting still open");
        require(!prop.executed, "NFTAccessDAO: already executed");
        require(prop.yesVotes > prop.noVotes, "NFTAccessDAO: proposal not passed");

        // --- Custom execution logic could go here ---
        // For example: call external contract, transfer funds, etc.

        prop.executed = true;
    }
}
