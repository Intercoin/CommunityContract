# CommunityBase

contracts/CommunityBase.sol

# Overview

Once installed will be use methods:

| **method name** | **called by** | **description** |
|-|-|-|
|<a href="#addmembers">addMembers</a>|everyone||
|<a href="#createrole">createRole</a>|everyone||
|<a href="#donateeth">donateETH</a>|everyone|one of the way to donate ETH to the contract in separate method. |
|<a href="#getintercoinaddress">getIntercoinAddress</a>|everyone||
|<a href="#getmembers">getMembers</a>|everyone||
|<a href="#getmembers">getMembers</a>|everyone||
|<a href="#getroles">getRoles</a>|everyone||
|<a href="#getroles">getRoles</a>|everyone||
|<a href="#grantroles">grantRoles</a>|everyone||
|<a href="#inviteaccept">inviteAccept</a>|everyone||
|<a href="#inviteprepare">invitePrepare</a>|everyone||
|<a href="#inviteview">inviteView</a>|everyone||
|<a href="#invitedby">invitedBy</a>|everyone||
|<a href="#managerole">manageRole</a>|everyone||
|<a href="#membercount">memberCount</a>|everyone||
|<a href="#membercount">memberCount</a>|everyone||
|<a href="#removemembers">removeMembers</a>|everyone||
|<a href="#revokeroles">revokeRoles</a>|everyone||
|<a href="#setintercoinaddress">setIntercoinAddress</a>|everyone||
## *Events*
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



## *StateVariables*
### DEFAULT_ADMINS_ROLE

> Notice: constant role name "admins" in bytes32


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



## *Functions*
### addMembers

> Notice: Added participants to role members

Arguments

| **name** | **type** | **description** |
|-|-|-|
| members | address[] | participant's addresses |



### createRole

> Notice: creating new role. can called owners role only

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | string | role name |



### donateETH

> Notice: one of the way to donate ETH to the contract in separate method. Second way is send directly `receive()`



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



### inviteAccept

> Details: // ==P== // format is "<some string data>:<address of communityContract>:<array of rolenames (sep=',')>:<some string data>"         // invite:0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC:judges,guests,admins:GregMagarshak // ==R== // format is "<address of R wallet>:<name of user>" // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4:John Doe 

Arguments

| **name** | **type** | **description** |
|-|-|-|
| p | string | invite message of admin whom generate messageHash and signed it |
| pSig | bytes | signature of admin whom generate invite and signed it |
| rp | string | message of recipient whom generate messageHash and signed it |
| rpSig | bytes | signature of recipient |



### invitePrepare

Arguments

| **name** | **type** | **description** |
|-|-|-|
| pSig | bytes | signature of admin whom generate invite and signed it |
| rpSig | bytes | signature of recipient |



### inviteView

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



### manageRole

> Notice: allow account with sourceRole setup targetRole to another account with default role(members)

Arguments

| **name** | **type** | **description** |
|-|-|-|
| sourceRole | string |  |
| targetRole | string |  |



### memberCount

> Notice: if call without params then returns count of all members with default role

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint256 | count of members |



### memberCount

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | string | role name |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint256 | count of members for that role |



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


