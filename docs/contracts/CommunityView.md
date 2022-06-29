# CommunityView

contracts/CommunityView.sol

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
|<a href="#addressescount">addressesCount</a>|everyone|all members count|
|<a href="#addressescount">addressesCount</a>|everyone|count of members for role|
|<a href="#approve">approve</a>|everyone|part of ERC721|
|<a href="#balanceof">balanceOf</a>|everyone|part of ERC721|
|<a href="#getaddresses">getAddresses</a>|everyone|all addresses belong to Role|
|<a href="#getapproved">getApproved</a>|everyone|part of ERC721|
|<a href="#getintercoinaddress">getIntercoinAddress</a>|everyone||
|<a href="#getroles">getRoles</a>|everyone|all roles|
|<a href="#getroles">getRoles</a>|everyone|member's roles|
|<a href="#granted">granted</a>|everyone||
|<a href="#grantedby">grantedBy</a>|everyone||
|<a href="#hook">hook</a>|everyone||
|<a href="#inviteview">inviteView</a>|everyone|viewing invite by admin signature|
|<a href="#invitedby">invitedBy</a>|everyone||
|<a href="#isaccounthasrole">isAccountHasRole</a>|everyone|checking is member belong to role|
|<a href="#isapprovedforall">isApprovedForAll</a>|everyone|part of ERC721|
|<a href="#istrustedforwarder">isTrustedForwarder</a>|everyone|checking if forwarder is trusted|
|<a href="#name">name</a>|everyone||
|<a href="#ownerof">ownerOf</a>|everyone|part of ERC721|
|<a href="#revoked">revoked</a>|everyone||
|<a href="#revokedby">revokedBy</a>|everyone||
|<a href="#safetransferfrom">safeTransferFrom</a>|everyone|part of ERC721|
|<a href="#safetransferfrom">safeTransferFrom</a>|everyone|part of ERC721|
|<a href="#setapprovalforall">setApprovalForAll</a>|everyone|part of ERC721|
|<a href="#setintercoinaddress">setIntercoinAddress</a>|everyone||
|<a href="#settrustedforwarder">setTrustedForwarder</a>|everyone||
|<a href="#supportsinterface">supportsInterface</a>|everyone|part of ERC721|
|<a href="#symbol">symbol</a>|everyone||
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



### addressesCount

> Notice: if call without params then returns count of all users which have at least one role

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint256 | count of members |



### addressesCount

> Notice: count of members for that role

Arguments

| **name** | **type** | **description** |
|-|-|-|
| roleIndex | uint8 | role index |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint256 | count of members for that role |



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



### getAddresses

> Notice: Returns all addresses belong to Role

> Details: can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389

Arguments

| **name** | **type** | **description** |
|-|-|-|
| rolesIndexes | uint8[] | array of roles indexes |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | address[] | array of address  |



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



### getRoles

> Notice: if call without params then returns all existing roles 

> Details: can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint8[] | array of roles  |
| -/- | string[] |  |
| -/- | string[] |  |



### getRoles

> Notice: Returns all roles which member belong to

> Details: can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389

Arguments

| **name** | **type** | **description** |
|-|-|-|
| members | address[] | member's addresses |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint8[] | l array of roles  |



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



### inviteView

> Notice: viewing invite by admin signature

Arguments

| **name** | **type** | **description** |
|-|-|-|
| sSig | bytes | signature of admin whom generate invite and signed it |

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



### isAccountHasRole

> Notice: is member has role

Arguments

| **name** | **type** | **description** |
|-|-|-|
| account | address | user address |
| rolename | string | role name |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bool | bool  |



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



### name

> Notice: getting name

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | string |  |



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



### symbol

> Notice: getting symbol

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | string |  |



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


