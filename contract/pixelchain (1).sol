
correct code


Chhota bhaii, [26-09-2025 14:27]
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/
 * @title PIXELCHAIN
 * @dev A comprehensive pixel art NFT platform for creating, trading, and showcasing digital pixel art
 * @author PIXELCHAIN Team
 */
contract Project {
    
    // Events
    event PixelArtCreated(uint256 indexed tokenId, address indexed creator, uint256 timestamp, string title);
    event PixelArtSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event CollaborationStarted(uint256 indexed collabId, address[] collaborators, uint256 canvasSize);
    event PixelUpdated(uint256 indexed tokenId, uint256 x, uint256 y, bytes3 color, address updatedBy);
    
    // Structs
    struct PixelArt {
        uint256 tokenId;
        address creator;
        string title;
        string description;
        uint256 canvasSize; // e.g., 32 for 32x32 pixel canvas
        mapping(uint256 => bytes3) pixels; // position => RGB color
        uint256 createdAt;
        uint256 price;
        bool isForSale;
        uint256 totalPixels;
        bool isCompleted;
    }
    
    struct Collaboration {
        uint256 collabId;
        address[] collaborators;
        uint256 canvasSize;
        mapping(uint256 => bytes3) canvas;
        mapping(address => bool) hasContributed;
        uint256 createdAt;
        bool isActive;
        uint256 contributionDeadline;
        string theme;
    }
    
    struct Artist {
        address artistAddress;
        string artistName;
        uint256 totalArtworks;
        uint256 totalSales;
        uint256 reputation; // 0-100 scale
        bool isVerified;
    }
    
    // State variables
    address public owner;
    uint256 public nextTokenId;
    uint256 public nextCollabId;
    uint256 public platformFeePercentage; // in basis points (100 = 1%)
    
    mapping(uint256 => PixelArt) public pixelArts;
    mapping(uint256 => address) public tokenOwners;
    mapping(address => uint256[]) public artistPortfolio;
    mapping(address => Artist) public artists;
    mapping(uint256 => Collaboration) public collaborations;
    mapping(address => uint256) public artistEarnings;
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "PIXELCHAIN: Only owner can perform this action");
        _;
    }
    
    modifier onlyTokenOwner(uint256 _tokenId) {
        require(tokenOwners[_tokenId] == msg.sender, "PIXELCHAIN: Only token owner can perform this action");
        _;
    }
    
    modifier validTokenId(uint256 _tokenId) {
        require(_tokenId < nextTokenId, "PIXELCHAIN: Invalid token ID");
        _;
    }
    
    modifier validCanvasSize(uint256 _size) {
        require(_size >= 8 && _size <= 128 && _size % 8 == 0, "PIXELCHAIN: Invalid canvas size");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        nextTokenId = 1;
        nextCollabId = 1;
        platformFeePercentage = 250; // 2.5%
    }
    
    /
     * @dev Core Function 1: Create Pixel Art NFT
     * @param _title Title of the pixel art
     * @param _description Description of the artwork
     * @param _canvasSize Size of the canvas (must be between 8-128 and divisible by 8)
     * @param _price Initial price for the artwork (0 if not for sale)
     */
    function createPixelArt(
        string memory _title,
        string memory _description,
        uint256 _canvasSize,
        uint256 _price
    ) external validCanvasSize(_canvasSize) returns (uint256) {
        require(bytes(_title).length > 0, "PIXELCHAIN: Title cannot be empty");
        
        uint256 tokenId = nextTokenId;
        
        // Initialize the pixel art
        PixelArt storage newArt = pixelArts[tokenId];
        newArt.tokenId = tokenId;
        newArt.creator = msg.sender;
        newArt.title = _title;
        newArt.description = _description;
        newArt.canvasSize = _canvasSize;
        newArt.createdAt = block.timestamp;
        newArt.price = _price;
        newArt.isForSale = _price > 0;
        newArt.totalPixels = 0;
        newArt.isCompleted = false;

Chhota bhaii, [26-09-2025 14:27]
// Set ownership
        tokenOwners[tokenId] = msg.sender;
        artistPortfolio[msg.sender].push(tokenId);
        
        // Update artist profile
        Artist storage artist = artists[msg.sender];
        if (artist.artistAddress == address(0)) {
            artist.artistAddress = msg.sender;
            artist.totalArtworks = 1;
            artist.reputation = 50; // Starting reputation
        } else {
            artist.totalArtworks++;
        }
        
        nextTokenId++;
        
        emit PixelArtCreated(tokenId, msg.sender, block.timestamp, _title);
        
        return tokenId;
    }
    
    /
     * @dev Core Function 2: Paint Pixels on Canvas
     * @param _tokenId ID of the pixel art token
     * @param _positions Array of pixel positions (calculated as y * canvasSize + x)
     * @param _colors Array of RGB colors corresponding to each position
     */
    function paintPixels(
        uint256 _tokenId,
        uint256[] memory _positions,
        bytes3[] memory _colors
    ) external validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        require(_positions.length == _colors.length, "PIXELCHAIN: Positions and colors length mismatch");
        require(_positions.length > 0, "PIXELCHAIN: No pixels to paint");
        require(!pixelArts[_tokenId].isCompleted, "PIXELCHAIN: Artwork is already completed");
        
        PixelArt storage art = pixelArts[_tokenId];
        uint256 maxPosition = art.canvasSize * art.canvasSize;
        
        for (uint256 i = 0; i < _positions.length; i++) {
            require(_positions[i] < maxPosition, "PIXELCHAIN: Invalid pixel position");
            
            // Only count as new pixel if it wasn't painted before
            if (art.pixels[_positions[i]] == 0x000000 && _colors[i] != 0x000000) {
                art.totalPixels++;
            } else if (art.pixels[_positions[i]] != 0x000000 && _colors[i] == 0x000000) {
                art.totalPixels--;
            }
            
            art.pixels[_positions[i]] = _colors[i];
            
            // Calculate x, y coordinates for event
            uint256 x = _positions[i] % art.canvasSize;
            uint256 y = _positions[i] / art.canvasSize;
            
            emit PixelUpdated(_tokenId, x, y, _colors[i], msg.sender);
        }
        
        // Check if artwork is completed (at least 50% filled)
        if (art.totalPixels >= (maxPosition / 2)) {
            art.isCompleted = true;
            artists[art.creator].reputation = _min(artists[art.creator].reputation + 5, 100);
        }
    }
    
    /
     * @dev Core Function 3: Buy Pixel Art NFT
     * @param _tokenId ID of the pixel art token to purchase
     */
    function buyPixelArt(uint256 _tokenId) external payable validTokenId(_tokenId) {
        PixelArt storage art = pixelArts[_tokenId];
        address seller = tokenOwners[_tokenId];
        
        require(art.isForSale, "PIXELCHAIN: Artwork is not for sale");
        require(msg.sender != seller, "PIXELCHAIN: Cannot buy your own artwork");
        require(msg.value >= art.price, "PIXELCHAIN: Insufficient payment");
        require(art.isCompleted, "PIXELCHAIN: Can only buy completed artworks");
        
        // Calculate fees
        uint256 platformFee = (art.price * platformFeePercentage) / 10000;
        uint256 sellerAmount = art.price - platformFee;
        
        // Transfer ownership
        tokenOwners[_tokenId] = msg.sender;
        art.isForSale = false;
        art.price = 0;
        
        // Update seller's portfolio (remove from seller)
        _removeFromPortfolio(seller, _tokenId);
        // Add to buyer's portfolio
        artistPortfolio[msg.sender].push(_tokenId);
        
        // Update artist stats
        artists[seller].totalSales++;
        artists[seller].reputation = _min(artists[seller].reputation + 3, 100);
        artistEarnings[seller] += sellerAmount;
        
        // Transfer payments
        payable(seller).transfer(sellerAmount);
        // Platform fee stays in contract
        
        // Refund excess payment

Chhota bhaii, [26-09-2025 14:27]
if (msg.value > art.price) {
            payable(msg.sender).transfer(msg.value - art.price);
        }
        
        emit PixelArtSold(_tokenId, seller, msg.sender, art.price);
    }
    
    // Additional Functions
    
    function startCollaboration(
        address[] memory _collaborators,
        uint256 _canvasSize,
        uint256 _deadline,
        string memory _theme
    ) external validCanvasSize(_canvasSize) returns (uint256) {
        require(_collaborators.length >= 2 && _collaborators.length <= 10, "PIXELCHAIN: Invalid collaborator count");
        require(_deadline > block.timestamp, "PIXELCHAIN: Invalid deadline");
        
        uint256 collabId = nextCollabId;
        
        Collaboration storage collab = collaborations[collabId];
        collab.collabId = collabId;
        collab.collaborators = _collaborators;
        collab.canvasSize = _canvasSize;
        collab.createdAt = block.timestamp;
        collab.isActive = true;
        collab.contributionDeadline = _deadline;
        collab.theme = _theme;
        
        nextCollabId++;
        
        emit CollaborationStarted(collabId, _collaborators, _canvasSize);
        
        return collabId;
    }
    
    function contributeToCollab(
        uint256 _collabId,
        uint256[] memory _positions,
        bytes3[] memory _colors
    ) external {
        require(_collabId < nextCollabId, "PIXELCHAIN: Invalid collaboration ID");
        
        Collaboration storage collab = collaborations[_collabId];
        require(collab.isActive, "PIXELCHAIN: Collaboration is not active");
        require(block.timestamp <= collab.contributionDeadline, "PIXELCHAIN: Collaboration deadline passed");
        
        bool isCollaborator = false;
        for (uint256 i = 0; i < collab.collaborators.length; i++) {
            if (collab.collaborators[i] == msg.sender) {
                isCollaborator = true;
                break;
            }
        }
        require(isCollaborator, "PIXELCHAIN: Not a collaborator");
        
        uint256 maxPosition = collab.canvasSize * collab.canvasSize;
        
        for (uint256 i = 0; i < _positions.length; i++) {
            require(_positions[i] < maxPosition, "PIXELCHAIN: Invalid pixel position");
            collab.canvas[_positions[i]] = _colors[i];
        }
        
        collab.hasContributed[msg.sender] = true;
    }
    
    function setArtistName(string memory _name) external {
        require(bytes(_name).length > 0, "PIXELCHAIN: Name cannot be empty");
        artists[msg.sender].artistName = _name;
        if (artists[msg.sender].artistAddress == address(0)) {
            artists[msg.sender].artistAddress = msg.sender;
            artists[msg.sender].reputation = 50;
        }
    }
    
    function listForSale(uint256 _tokenId, uint256 _price) external validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        require(_price > 0, "PIXELCHAIN: Price must be greater than 0");
        require(pixelArts[_tokenId].isCompleted, "PIXELCHAIN: Can only sell completed artworks");
        
        pixelArts[_tokenId].price = _price;
        pixelArts[_tokenId].isForSale = true;
    }
    
    function removeFromSale(uint256 _tokenId) external validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        pixelArts[_tokenId].isForSale = false;
        pixelArts[_tokenId].price = 0;
    }
    
    function getPixel(uint256 _tokenId, uint256 _position) external view validTokenId(_tokenId) returns (bytes3) {
        return pixelArts[_tokenId].pixels[_position];
    }
    
    function getArtistPortfolio(address _artist) external view returns (uint256[] memory) {
        return artistPortfolio[_artist];
    }
    
    function getCollaborators(uint256 _collabId) external view returns (address[] memory) {
        return collaborations[_collabId].collaborators;
    }
    
    function withdrawEarnings() external {
        uint256 earnings = artistEarnings[msg.sender];
        require(earnings > 0, "PIXELCHAIN: No earnings to withdraw");
        
        artistEarnings[msg.sender] = 0;

Chhota bhaii, [26-09-2025 14:27]
payable(msg.sender).transfer(earnings);
    }
    
    function withdrawPlatformFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "PIXELCHAIN: No fees to withdraw");
        
        payable(owner).transfer(balance);
    }
    
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 1000, "PIXELCHAIN: Fee cannot exceed 10%");
        platformFeePercentage = _feePercentage;
    }
    
    function verifyArtist(address _artist) external onlyOwner {
        require(artists[_artist].artistAddress != address(0), "PIXELCHAIN: Artist does not exist");
        artists[_artist].isVerified = true;
        artists[_artist].reputation = _min(artists[_artist].reputation + 10, 100);
    }
    
    // Helper functions
    function _removeFromPortfolio(address _artist, uint256 _tokenId) internal {
        uint256[] storage portfolio = artistPortfolio[_artist];
        for (uint256 i = 0; i < portfolio.length; i++) {
            if (portfolio[i] == _tokenId) {
                portfolio[i] = portfolio[portfolio.length - 1];
                portfolio.pop();
                break;
            }
        }
    }
    
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
