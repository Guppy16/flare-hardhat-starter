// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ContractRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/ContractRegistry.sol";

// Dummy import to get artifacts for IFDCHubs
import {IFdcHub} from "@flarenetwork/flare-periphery-contracts/coston2/IFdcHub.sol";
import {IFdcRequestFeeConfigurations} from "@flarenetwork/flare-periphery-contracts/coston2/IFdcRequestFeeConfigurations.sol";

import {IJsonApiVerification} from "@flarenetwork/flare-periphery-contracts/coston2/IJsonApiVerification.sol";
import {IJsonApi} from "@flarenetwork/flare-periphery-contracts/coston2/IJsonApi.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

struct StarWarsCharacter {
    string name;
    uint256 numberOfMovies;
    uint256 apiUid;
    uint256 bmi;
}

struct DataTransportObject {
    string name;
    uint256 height;
    uint256 mass;
    uint256 numberOfMovies;
    uint256 apiUid;
}

// struct NYTDocument {
//     string abstract_; // abstract is a reserved keyword
//     string webUrl;
//     string snippet;
//     string leadParagraph;
//     string mainHead;
//     string printHeadline;
//     string[] keywords;
//     string pubDate;
//     string _id;
// }

struct DocumentsTransferObject {
    string webUrl;
    string id;
}

struct NYTDocument {
    string webUrl;
    string id;
}

struct NewsEvent {
    string category;
    string date;
}

contract StarWarsCharacterList {
    mapping(uint256 => StarWarsCharacter) public characters;
    uint256[] public characterIds;

    mapping(string => NYTDocument) public nytDocuments; // mapping: NYTDocument id -> NYTDocument
    string[] public nytDocumentIds; // NYTDocument ids

    mapping(string => NewsEvent) public newsEvents; // mapping: date -> CryptoEvent
    string[] public newsEventDates; // CryptoEvent dates

    function isJsonApiProofValid(
        IJsonApi.Proof calldata _proof
    ) public view returns (bool) {
        // Inline the check for now until we have an official contract deployed
        return
            ContractRegistry.auxiliaryGetIJsonApiVerification().verifyJsonApi(
                _proof
            );
    }

    function addCharacter(IJsonApi.Proof calldata data) public {
        require(isJsonApiProofValid(data), "Invalid proof");

        DataTransportObject memory dto = abi.decode(
            data.data.responseBody.abi_encoded_data,
            (DataTransportObject)
        );

        require(characters[dto.apiUid].apiUid == 0, "Character already exists");

        StarWarsCharacter memory character = StarWarsCharacter({
            name: dto.name,
            numberOfMovies: dto.numberOfMovies,
            apiUid: dto.apiUid,
            bmi: (dto.mass * 100 * 100) / (dto.height * dto.height)
        });

        characters[dto.apiUid] = character;
        characterIds.push(dto.apiUid);
    }

    function addNYTDocument(IJsonApi.Proof calldata data) public {
        require(isJsonApiProofValid(data), "Invalid proof");

        // Decode a list of DocumentsTransferObject
        DocumentsTransferObject[] memory dtos = abi.decode(
            data.data.responseBody.abi_encoded_data,
            (DocumentsTransferObject[])
        );

        for (uint256 i = 0; i < dtos.length; i++) {
            NYTDocument memory nytDocument = NYTDocument({
                webUrl: dtos[i].webUrl,
                id: dtos[i].id
            });

            nytDocuments[dtos[i].id] = nytDocument;
            nytDocumentIds.push(dtos[i].id);
        }
    }

    function addNewsEvent(IJsonApi.Proof calldata data) public {
        require(isJsonApiProofValid(data), "Invalid proof");

        // Decode a news event
        NewsEvent memory event_ = abi.decode(
            data.data.responseBody.abi_encoded_data,
            (NewsEvent)
        );

        require(
            keccak256(bytes(newsEvents[event_.date].date)) == keccak256(bytes("")),
            "Event already exists"
        );

        newsEvents[event_.date] = event_;
        newsEventDates.push(event_.date);
    }

    function getAllCharacters()
        public
        view
        returns (StarWarsCharacter[] memory)
    {
        StarWarsCharacter[] memory result = new StarWarsCharacter[](
            characterIds.length
        );
        for (uint256 i = 0; i < characterIds.length; i++) {
            result[i] = characters[characterIds[i]];
        }
        return result;
    }

    function getAllDocuments()
        public
        view
        returns (NYTDocument[] memory)
    {
        NYTDocument[] memory result = new NYTDocument[](
            nytDocumentIds.length
        );
        for (uint256 i = 0; i < nytDocumentIds.length; i++) {
            result[i] = nytDocuments[nytDocumentIds[i]];
        }
        return result;
    }

    function getAllNewsEvents() public view returns (NewsEvent[] memory) {
        NewsEvent[] memory result = new NewsEvent[](newsEventDates.length);
        for (uint256 i = 0; i < newsEventDates.length; i++) {
            result[i] = newsEvents[newsEventDates[i]];
        }
        return result;
    }

    function getFdcHub() external view returns (IFdcHub) {
        return ContractRegistry.getFdcHub();
    }

    function getFdcRequestFeeConfigurations()
        external
        view
        returns (IFdcRequestFeeConfigurations)
    {
        return ContractRegistry.getFdcRequestFeeConfigurations();
    }
}
