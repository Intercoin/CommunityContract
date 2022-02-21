# CommunityERC721

Extend Community Smart contract. Each role it's ERC721 token, URI can be set by user who can manage. Also any user who belong to role can set ExtraURI <br>

# Overview

Once installed will be use methods:

| **method name** | **called by** | **description** |
|-|-|-|
|<a href="#default_admins_role">DEFAULT_ADMINS_ROLE</a>|everyone||
|<a href="#default_members_role">DEFAULT_MEMBERS_ROLE</a>|everyone||
|<a href="#default_owners_role">DEFAULT_OWNERS_ROLE</a>|everyone||
|<a href="#default_relayers_role">DEFAULT_RELAYERS_ROLE</a>|everyone||
|<a href="#replenish_amount">REPLENISH_AMOUNT</a>|everyone||
|<a href="#reward_amount">REWARD_AMOUNT</a>|everyone||
|<a href="#addmembers">addMembers</a>|owners|Added participants to role members|
|<a href="#approve">approve</a>|everyone|part of ERC721|
|<a href="#balanceof">balanceOf</a>|everyone|part of ERC721|
|<a href="#createrole">createRole</a>|everyone|creating new role. can called owners role only|
|<a href="#donateeth">donateETH</a>|everyone|one of the way to donate ETH to the contract in separate method. |
|<a href="#getapproved">getApproved</a>|everyone|part of ERC721|
|<a href="#getintercoinaddress">getIntercoinAddress</a>|everyone||
|<a href="#getmembers">getMembers</a>|everyone|all members belong to Role|
|<a href="#getmembers">getMembers</a>|everyone|`DEFAULT_MEMBERS_ROLE` members|
|<a href="#getroles">getRoles</a>|everyone|all roles|
|<a href="#getroles">getRoles</a>|everyone|member's roles|
|<a href="#grantroles">grantRoles</a>|everyone|Added new Roles for members|
|<a href="#granted">granted</a>|everyone||
|<a href="#grantedby">grantedBy</a>|everyone||
|<a href="#init">init</a>|everyone||
|<a href="#inviteaccept">inviteAccept</a>|everyone|accepting invite|
|<a href="#inviteprepare">invitePrepare</a>|everyone|registering invite |
|<a href="#inviteview">inviteView</a>|everyone|viewing invite by admin signature|
|<a href="#invitedby">invitedBy</a>|everyone||
|<a href="#isapprovedforall">isApprovedForAll</a>|everyone|part of ERC721|
|<a href="#managerole">manageRole</a>|everyone|allow managing another role|
|<a href="#membercount">memberCount</a>|everyone|all members count|
|<a href="#membercount">memberCount</a>|everyone|count of members for role|
|<a href="#ownerof">ownerOf</a>|everyone|part of ERC721|
|<a href="#removemembers">removeMembers</a>|owners|Removed participants from  role members|
|<a href="#revokeroles">revokeRoles</a>|everyone|Removed Role for member|
|<a href="#revoked">revoked</a>|everyone||
|<a href="#revokedby">revokedBy</a>|everyone||
|<a href="#safetransferfrom">safeTransferFrom</a>|everyone|part of ERC721|
|<a href="#safetransferfrom">safeTransferFrom</a>|everyone|part of ERC721|
|<a href="#setapprovalforall">setApprovalForAll</a>|everyone|part of ERC721|
|<a href="#setextrauri">setExtraURI</a>|any who belong to role||
|<a href="#setintercoinaddress">setIntercoinAddress</a>|everyone||
|<a href="#setroleuri">setRoleURI</a>|any who can manage this role|setting tokenURI for role|
|<a href="#supportsinterface">supportsInterface</a>|everyone|part of ERC721|
|<a href="#tokenuri">tokenURI</a>|everyone|getting tokenURI|
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
| sourceRole | bytes32 | indexed |
| targetRole | bytes32 | indexed |
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
### name

> Notice: getting name


| **type** |
|-|
|string|



### symbol

> Notice: getting symbol


| **type** |
|-|
|string|



## *Functions*
### DEFAULT_ADMINS_ROLE

> Notice: constant role name "admins" in bytes32

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



### addMembers

> Notice: Added participants to role members

Arguments

| **name** | **type** | **description** |
|-|-|-|
| members | address[] | participant's addresses |



### approve

> Notice: getting part of ERC721

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | uint256 |  |



### balanceOf

> Notice: getting balance of owner address

Arguments

| **name** | **type** | **description** |
|-|-|-|
| account | address | user's address |

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



### donateETH

> Notice: one of the way to donate ETH to the contract in separate method. Second way is send directly `receive()`



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



### getMembers

> Notice: Returns all members belong to Role

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | string | role name |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | address[] | array of address  |



### getMembers

> Notice: if call without params then returns all members belong to `DEFAULT_MEMBERS_ROLE`

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | address[] | array of address  |



### getRoles

> Notice: if call without params then returns all existing roles 

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | string[] | array of roles  |



### getRoles

> Notice: Returns all roles which member belong to

Arguments

| **name** | **type** | **description** |
|-|-|-|
| member | address | member's address |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | string[] | array of roles  |



### grantRoles

> Notice: Added new Roles for members

Arguments

| **name** | **type** | **description** |
|-|-|-|
| members | address[] | participant's addresses |
| roles | string[] | Roles name |



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



### init

Arguments

| **name** | **type** | **description** |
|-|-|-|
| name_ | string | erc721 name |
| symbol_ | string | erc721 symbol |



### inviteAccept

> Notice: accepting invite

> Details: @dev ==P==  format is "<some string data>:<address of communityContract>:<array of rolenames (sep=',')>:<some string data>"          invite:0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC:judges,guests,admins:GregMagarshak  ==R==  format is "<address of R wallet>:<name of user>"  0x5B38Da6a701c568545dCfcB03FcB875f56beddC4:John Doe  

Arguments

| **name** | **type** | **description** |
|-|-|-|
| p | string | invite message of admin whom generate messageHash and signed it |
| pSig | bytes | signature of admin whom generate invite and signed it |
| rp | string | message of recipient whom generate messageHash and signed it |
| rpSig | bytes | signature of recipient |



### invitePrepare

> Notice: registering invite,. calling by relayers

Arguments

| **name** | **type** | **description** |
|-|-|-|
| pSig | bytes | signature of admin whom generate invite and signed it |
| rpSig | bytes | signature of recipient |



### inviteView

> Notice: viewing invite by admin signature

Arguments

| **name** | **type** | **description** |
|-|-|-|
| pSig | bytes | signature of admin whom generate invite and signed it |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | tuple | structure inviteSignature |



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



### manageRole

> Notice: allow account with sourceRole setup targetRole to another account with default role(members)

Arguments

| **name** | **type** | **description** |
|-|-|-|
| sourceRole | string | role which will manage targetRole |
| targetRole | string | role will have been managed by sourceRole |



### memberCount

> Notice: if call without params then returns count of all members with default role

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint256 | count of members |



### memberCount

> Notice: count of members for that role

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | string | role name |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint256 | count of members for that role |



### ownerOf

> Notice: getting owner of tokenId

Arguments

| **name** | **type** | **description** |
|-|-|-|
| tokenId | uint256 | tokenId |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| owner | address |  |



### removeMembers

> Notice: Removed participants from  role members

Arguments

| **name** | **type** | **description** |
|-|-|-|
| members | address[] | participant's addresses |



### revokeRoles

> Notice: Removed Role for member

Arguments

| **name** | **type** | **description** |
|-|-|-|
| members | address[] | participant's addresses |
| roles | string[] | Roles name |



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
| role | string |  |
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
| role | string | role name |
| roleURI | string | token URI |



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

> Notice: getting tokenURI(part of ERC721)

Arguments

| **name** | **type** | **description** |
|-|-|-|
| tokenId | uint256 | token ID |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | string | tokenuri |



### transferFrom

> Notice: getting part of ERC721

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |
| -/- | address |  |
| -/- | uint256 |  |


