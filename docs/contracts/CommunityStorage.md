# CommunityStorage

contracts/CommunityStorage.sol

# Overview

Once installed will be use methods:

| **method name** | **called by** | **description** |
|-|-|-|
|<a href="#approve">approve</a>|everyone|part of ERC721|
|<a href="#balanceof">balanceOf</a>|everyone||
|<a href="#getapproved">getApproved</a>|everyone|part of ERC721|
|<a href="#getintercoinaddress">getIntercoinAddress</a>|everyone||
|<a href="#hook">hook</a>|everyone||
|<a href="#invitedby">invitedBy</a>|everyone||
|<a href="#isapprovedforall">isApprovedForAll</a>|everyone|part of ERC721|
|<a href="#istrustedforwarder">isTrustedForwarder</a>|everyone|checking if forwarder is trusted|
|<a href="#ownerof">ownerOf</a>|everyone||
|<a href="#safetransferfrom">safeTransferFrom</a>|everyone|part of ERC721|
|<a href="#safetransferfrom">safeTransferFrom</a>|everyone|part of ERC721|
|<a href="#setapprovalforall">setApprovalForAll</a>|everyone|part of ERC721|
|<a href="#setintercoinaddress">setIntercoinAddress</a>|everyone||
|<a href="#settrustedforwarder">setTrustedForwarder</a>|everyone||
|<a href="#supportsinterface">supportsInterface</a>|everyone|part of ERC721|
|<a href="#tokenuri">tokenURI</a>|everyone||
|<a href="#transferfrom">transferFrom</a>|everyone|part of ERC721|
## *Events*
### Approval

Arguments

| **name** | **type** | **description** |
|-|-|-|
| owner | address | indexed |
| approved | address | indexed |
| tokenId | uint256 | indexed |



### ApprovalForAll

Arguments

| **name** | **type** | **description** |
|-|-|-|
| owner | address | indexed |
| operator | address | indexed |
| approved | bool | not indexed |



### Initialized

Arguments

| **name** | **type** | **description** |
|-|-|-|
| version | uint8 | not indexed |



### RoleAddedErrorMessage

Arguments

| **name** | **type** | **description** |
|-|-|-|
| sender | address | indexed |
| msg | string | not indexed |



### RoleCreated

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | bytes32 | indexed |
| sender | address | indexed |



### RoleGranted

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | bytes32 | indexed |
| account | address | indexed |
| sender | address | indexed |



### RoleManaged

Arguments

| **name** | **type** | **description** |
|-|-|-|
| sourceRole | uint8 | indexed |
| targetRole | uint8 | indexed |
| canGrantRole | bool | not indexed |
| canRevokeRole | bool | not indexed |
| requireRole | uint8 | not indexed |
| maxAddresses | uint256 | not indexed |
| duration | uint64 | not indexed |
| sender | address | indexed |



### RoleRevoked

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | bytes32 | indexed |
| account | address | indexed |
| sender | address | indexed |



### Transfer

Arguments

| **name** | **type** | **description** |
|-|-|-|
| from | address | indexed |
| to | address | indexed |
| tokenId | uint256 | indexed |



## *StateVariables*
### DEFAULT_ADMINS_ROLE

> Notice: constant role name "admins" in bytes32


| **type** |
|-|
|bytes32|



### DEFAULT_ALUMNI_ROLE

> Notice: constant role name "alumni" in bytes32


| **type** |
|-|
|bytes32|



### DEFAULT_MEMBERS_ROLE

> Notice: constant role name "members" in bytes32


| **type** |
|-|
|bytes32|



### DEFAULT_OWNERS_ROLE

> Notice: constant role name "owners" in bytes32


| **type** |
|-|
|bytes32|



### DEFAULT_RELAYERS_ROLE

> Notice: constant role name "relayers" in bytes32


| **type** |
|-|
|bytes32|



### DEFAULT_VISITORS_ROLE

> Notice: constant role name "visitors" in bytes32


| **type** |
|-|
|bytes32|



### REPLENISH_AMOUNT

> Notice: constant reward amount that user-recepient will replenish


| **type** |
|-|
|uint256|



### REWARD_AMOUNT

> Notice: constant reward that user-relayers will obtain


| **type** |
|-|
|uint256|



### granted

> Notice: history of users granted

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | uint256 |  |


| **type** |
|-|
|address|
|uint64|
|uint32|



### grantedBy

> Notice: map users granted by

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | uint256 |  |


| **type** |
|-|
|address|
|uint64|
|uint32|



### name

> Notice: getting name


| **type** |
|-|
|string|



### revoked

> Notice: history of users revoked

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | uint256 |  |


| **type** |
|-|
|address|
|uint64|
|uint32|



### revokedBy

> Notice: map users revoked by

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | uint256 |  |


| **type** |
|-|
|address|
|uint64|
|uint32|



### symbol

> Notice: getting symbol


| **type** |
|-|
|string|



## *Functions*
### approve

> Notice: getting part of ERC721

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | uint256 |  |



### balanceOf

Arguments

| **name** | **type** | **description** |
|-|-|-|
| account | address |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| balance | uint256 |  |



### getApproved

> Notice: getting part of ERC721

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint256 |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |



### getIntercoinAddress

> Notice: got stored intercoin address

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |



### hook

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |



### invitedBy

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |



### isApprovedForAll

> Notice: getting part of ERC721

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | address |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bool |  |



### isTrustedForwarder

> Details: checking if forwarder is trusted

Arguments

| **name** | **type** | **description** |
|-|-|-|
| forwarder | address | trustedforwarder's address to check |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bool |  |



### ownerOf

> Details: Returns the owner of the `tokenId` token. Requirements: - `tokenId` must exist.

Arguments

| **name** | **type** | **description** |
|-|-|-|
| tokenId | uint256 |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| owner | address |  |



### safeTransferFrom

> Notice: getting part of ERC721

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | address |  |
| -/- | uint256 |  |



### safeTransferFrom

> Notice: getting part of ERC721

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | address |  |
| -/- | uint256 |  |
| -/- | bytes |  |



### setApprovalForAll

> Notice: getting part of ERC721

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | bool |  |



### setIntercoinAddress

> Notice: setup intercoin contract's address. happens once while initialization through factory

Arguments

| **name** | **type** | **description** |
|-|-|-|
| addr | address | address of intercoin contract |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bool |  |



### setTrustedForwarder

Arguments

| **name** | **type** | **description** |
|-|-|-|
| forwarder | address |  |



### supportsInterface

> Notice: getting part of ERC721

Arguments

| **name** | **type** | **description** |
|-|-|-|
| interfaceId | bytes4 |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bool |  |



### tokenURI

> Details: Returns the Uniform Resource Identifier (URI) for `tokenId` token.

Arguments

| **name** | **type** | **description** |
|-|-|-|
| tokenId | uint256 |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | string |  |



### transferFrom

> Notice: getting part of ERC721

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | address |  |
| -/- | uint256 |  |


