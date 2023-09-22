// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "solady/src/utils/LibSort.sol";

/**
 * @title TrustfulOracle
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 * @notice A price oracle with a number of trusted sources that individually report prices for symbols.
 *         The oracle's price for a given symbol is the median price of the symbol over all sources.
 */

contract TrustfulOracle is AccessControlEnumerable {
    uint256 public constant MIN_SOURCES = 1;
    bytes32 public constant TRUSTED_SOURCE_ROLE = keccak256("TRUSTED_SOURCE_ROLE");
    bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");

    // Source address => (symbol => price)
    mapping(address => mapping(string => uint256)) private _pricesBySource;

    error NotEnoughSources();

    event UpdatedPrice(address indexed source, string indexed symbol, uint256 oldPrice, uint256 newPrice);

/* AccessControl: mark _setupRole(bytes32,address) as deprecated in favor of _grantRole(bytes32,address) */

    constructor(address[] memory sources, bool enableInitialization) {
        if (sources.length < MIN_SOURCES)
            revert NotEnoughSources();
        for (uint256 i = 0; i < sources.length;) {
            unchecked {
                _setupRole(TRUSTED_SOURCE_ROLE, sources[i]);           // _grantRole(bytes32,address)
                ++i;
            }
        }
        if (enableInitialization)
            _setupRole(INITIALIZER_ROLE, msg.sender);
    }

    // A handy utility allowing the deployer to setup initial prices (only once)
    // can only be called once
    function setupInitialPrices(address[] calldata sources, string[] calldata symbols, uint256[] calldata prices)
        external
        onlyRole(INITIALIZER_ROLE)
    {
        // Only allow one (symbol, price) per source
        require(sources.length == symbols.length && symbols.length == prices.length);
        for (uint256 i = 0; i < sources.length;) {
            unchecked {
                _setPrice(sources[i], symbols[i], prices[i]);
                ++i;
            }
        }
        renounceRole(INITIALIZER_ROLE, msg.sender);
    }


// can only be called by the pre-assigned "source contracts"
    function postPrice(string calldata symbol, uint256 newPrice) external onlyRole(TRUSTED_SOURCE_ROLE) {
        _setPrice(msg.sender, symbol, newPrice);
    }


// getter function to obtain the median price of an asset
    function getMedianPrice(string calldata symbol) external view returns (uint256) {
        return _computeMedianPrice(symbol);
    }

// returns an array of prices obtained from pre-approved trusted sources
    function getAllPricesForSymbol(string memory symbol) public view returns (uint256[] memory prices) {

        // returns the number of sources for a given 'symbol'
        uint256 numberOfSources = getRoleMemberCount(TRUSTED_SOURCE_ROLE);

        // initiating a fixed size array with length = no of sources
        prices = new uint256[](numberOfSources);

        // populates the prices array
        for (uint256 i = 0; i < numberOfSources;) {

            // accesses the Enumerable mapping from the AccessControlEnumerable contract
            address source = getRoleMember(TRUSTED_SOURCE_ROLE, i);  
            prices[i] = getPriceBySource(symbol, source);
            unchecked { ++i; }
        }
    }


// returns the price from the mapping "mapping(address => mapping(string => uint256)) private _pricesBySource"
//                                      Source address =>        (symbol => price)
    function getPriceBySource(string memory symbol, address source) public view returns (uint256) {
        return _pricesBySource[source][symbol];
    }


// Updates the state mapping "_pricesBySource"  
// called by  "setupInitialPrices()"
    function _setPrice(address source, string memory symbol, uint256 newPrice) private {
        uint256 oldPrice = _pricesBySource[source][symbol];
        _pricesBySource[source][symbol] = newPrice;
        emit UpdatedPrice(source, symbol, oldPrice, newPrice);
    }


    function _computeMedianPrice(string memory symbol) private view returns (uint256) {
        uint256[] memory prices = getAllPricesForSymbol(symbol);
        // sorting the prices in increasing order - low to high
        LibSort.insertionSort(prices);

        // If Even -- we take the average of 2 median prices
        if (prices.length % 2 == 0) {
            uint256 leftPrice = prices[(prices.length / 2) - 1];
            uint256 rightPrice = prices[prices.length / 2];
            return (leftPrice + rightPrice) / 2;

        } else { // If Odd -- we take the single median price
            return prices[prices.length / 2];
        }
    }
}
