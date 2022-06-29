# CommunityState

contracts/CommunityState.sol

# Overview

Once installed will be use methods:

| **method name** | **called by** | **description** |
|-|-|-|
|<a href="#default_admins_role">DEFAULT_ADMINS_ROLE</a>|everyone||
|<a href="#default_alumni_role">DEFAULT_ALUMNI_ROLE</a>|everyone||
|<a href="#default_members_role">DEFAULT_MEMBERS_ROLE</a>|everyone||
|<a href="#default_owners_role">DEFAULT_OWNERS_ROLE</a>|everyone||
|<a href="#default_relayers_role">DEFAULT_RELAYERS_ROLE</a>|everyone||
|<a href="#default_visitors_role">DEFAULT_VISITORS_ROLE</a>|everyone||
|<a href="#replenish_amount">REPLENISH_AMOUNT</a>|everyone||
|<a href="#reward_amount">REWARD_AMOUNT</a>|everyone||
|<a href="#approve">approve</a>|everyone|part of ERC721|
|<a href="#balanceof">balanceOf</a>|everyone||
|<a href="#createrole">createRole</a>|everyone|creating new role. can called owners role only|
|<a href="#getapproved">getApproved</a>|everyone|part of ERC721|
|<a href="#getintercoinaddress">getIntercoinAddress</a>|everyone||
|<a href="#grantroles">grantRoles</a>|everyone|Added new Roles for each account|
|<a href="#granted">granted</a>|everyone||
|<a href="#grantedby">grantedBy</a>|everyone||
|<a href="#hook">hook</a>|everyone||
|<a href="#initialize">initialize</a>|everyone||
|<a href="#inviteaccept">inviteAccept</a>|everyone|accepting invite|
|<a href="#inviteprepare">invitePrepare</a>|everyone|registering invite |
|<a href="#invitedby">invitedBy</a>|everyone||
|<a href="#isapprovedforall">isApprovedForAll</a>|everyone|part of ERC721|
|<a href="#istrustedforwarder">isTrustedForwarder</a>|everyone|checking if forwarder is trusted|
|<a href="#managerole">manageRole</a>|everyone||
|<a href="#name">name</a>|everyone||
|<a href="#ownerof">ownerOf</a>|everyone||
|<a href="#revokeroles">revokeRoles</a>|everyone|Removed Roles from each member|
|<a href="#revoked">revoked</a>|everyone||
|<a href="#revokedby">revokedBy</a>|everyone||
|<a href="#safetransferfrom">safeTransferFrom</a>|everyone|part of ERC721|
|<a href="#safetransferfrom">safeTransferFrom</a>|everyone|part of ERC721|
|<a href="#setapprovalforall">setApprovalForAll</a>|everyone|part of ERC721|
|<a href="#setextrauri">setExtraURI</a>|any who belong to role||
|<a href="#setintercoinaddress">setIntercoinAddress</a>|everyone||
|<a href="#setroleuri">setRoleURI</a>|any who can manage this role|setting tokenURI for role|
|<a href="#settrustedforwarder">setTrustedForwarder</a>|everyone||
|<a href="#supportsinterface">supportsInterface</a>|everyone|part of ERC721|
|<a href="#symbol">symbol</a>|everyone||
|<a href="#tokenuri">tokenURI</a>|everyone||
|<a href="#transferfrom">transferFrom</a>|everyone|part of ERC721|
|<a href="#withdrawremainingbalance">withdrawRemainingBalance</a>|owners|the way to withdraw ETH from the contract.|
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



## *Functions*
### DEFAULT_ADMINS_ROLE

> Notice: constant role name "admins" in bytes32

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bytes32 |  |



### DEFAULT_ALUMNI_ROLE

> Notice: constant role name "alumni" in bytes32

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bytes32 |  |



### DEFAULT_MEMBERS_ROLE

> Notice: constant role name "members" in bytes32

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bytes32 |  |



### DEFAULT_OWNERS_ROLE

> Notice: constant role name "owners" in bytes32

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bytes32 |  |



### DEFAULT_RELAYERS_ROLE

> Notice: constant role name "relayers" in bytes32

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bytes32 |  |



### DEFAULT_VISITORS_ROLE

> Notice: constant role name "visitors" in bytes32

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bytes32 |  |



### REPLENISH_AMOUNT

> Notice: constant reward amount that user-recepient will replenish

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint256 |  |



### REWARD_AMOUNT

> Notice: constant reward that user-relayers will obtain

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint256 |  |



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



### createRole

> Notice: creating new role. can called owners role only

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | string | role name |



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



### grantRoles

> Notice: Added new Roles for each account

Arguments

| **name** | **type** | **description** |
|-|-|-|
| accounts | address[] | participant's addresses |
| rolesIndexes | uint8[] | Roles indexes |



### granted

> Notice: history of users granted

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | uint256 |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| actor | address |  |
| timestamp | uint64 |  |
| extra | uint32 |  |



### grantedBy

> Notice: map users granted by

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | uint256 |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| actor | address |  |
| timestamp | uint64 |  |
| extra | uint32 |  |



### hook

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |



### initialize

Arguments

| **name** | **type** | **description** |
|-|-|-|
| hook | address | address of contract implemented ICommunityHook interface. Can be address(0) |
| name_ | string | erc721 name |
| symbol_ | string | erc721 symbol |



### inviteAccept

> Notice: accepting invite

> Details: @dev ==P==  format is "<some string data>:<address of communityContract>:<array of rolenames (sep=',')>:<some string data>"          invite:0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC:judges,guests,admins:GregMagarshak  ==R==  format is "<address of R wallet>:<name of user>"  0x5B38Da6a701c568545dCfcB03FcB875f56beddC4:John Doe  

Arguments

| **name** | **type** | **description** |
|-|-|-|
| p | string | invite message of admin whom generate messageHash and signed it |
| sSig | bytes | signature of admin whom generate invite and signed it |
| rp | string | message of recipient whom generate messageHash and signed it |
| rSig | bytes | signature of recipient |



### invitePrepare

> Notice: registering invite,. calling by relayers

Arguments

| **name** | **type** | **description** |
|-|-|-|
| sSig | bytes | signature of admin whom generate invite and signed it |
| rSig | bytes | signature of recipient |



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



### manageRole

> Notice: allow account with byRole: (if canGrantRole ==true) grant ofRole to another account if account has requireRole          it can be available `maxAddresses` during `duration` time          if duration == 0 then no limit by time: `maxAddresses` will be max accounts on this role          if maxAddresses == 0 then no limit max accounts on this role (if canRevokeRole ==true) revoke ofRole from account.

Arguments

| **name** | **type** | **description** |
|-|-|-|
| byRole | uint8 |  |
| ofRole | uint8 |  |
| canGrantRole | bool |  |
| canRevokeRole | bool |  |
| requireRole | uint8 |  |
| maxAddresses | uint256 |  |
| duration | uint64 |  |



### name

> Notice: getting name

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | string |  |



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



### revokeRoles

> Notice: Removed Roles from each member

Arguments

| **name** | **type** | **description** |
|-|-|-|
| accounts | address[] | participant's addresses |
| rolesIndexes | uint8[] | Roles indexes |



### revoked

> Notice: history of users revoked

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | uint256 |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| actor | address |  |
| timestamp | uint64 |  |
| extra | uint32 |  |



### revokedBy

> Notice: map users revoked by

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | uint256 |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| actor | address |  |
| timestamp | uint64 |  |
| extra | uint32 |  |



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



### setExtraURI

> Notice: setting extraURI for role.

Arguments

| **name** | **type** | **description** |
|-|-|-|
| roleIndex | uint8 |  |
| extraURI | string |  |



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



### setRoleURI

> Notice: setting tokenURI for role

Arguments

| **name** | **type** | **description** |
|-|-|-|
| roleIndex | uint8 | role index |
| roleURI | string | token URI |



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



### symbol

> Notice: getting symbol

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | string |  |



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



### withdrawRemainingBalance

> Notice: the way to withdraw remaining ETH from the contract. called by owners only 


