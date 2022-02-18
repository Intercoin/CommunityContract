# CommunityContract
Smart contract for managing community membership and roles.   
There are two versions: [Community](docs/contracts/Community.md) and [CommunityERC721](docs/contracts/CommunityERC721.md).   
Community is a contract for managing community membership and roles.    
CommunityERC721 - the same as Community but create NFT for each role. User can customize own NFT and specify ExtraURI    

# Deploy Initial 
Deployer will create two implementations and deploy CommunityFactory that produced Community and CommunityERC721.

# Deploy
Any user can create own community by call method produce of CommunityFactory contract: [produce](docs/contracts/CommunityFactory.md#produce) and [produce(name, symbol)](docs/contracts/CommunityFactory.md#produce-1) respectively

# Overview
There are 4 predefined roles:   

role name| role index
--|--
`owners`|1
`admins`|2
`members`|3
`relayers`|4


Role `members` is starting role for any new accounts.   
Roles `owners` and `admins` can manage `members` and any newly created roles.   
Role `relayers` is web servers X which can register member in community via invite by owners/admins or some who can manage.   
Roles `owners` is a single role that can magage itself. means one owner can add(or remove) other owner.   
   
   
Contract can be used as external storage for getting list of memebers.   
   

In cases with CommunityERC721 any user obtain NFT with tokenID = `(roleid <<160)+walletaddress`   
Any who can manage certain role can setup tokenURI for this role by calling `setRoleURI` .  
Also any member can setup personal URI for this role by calling `setExtraURI`.   

Full methods for each contracts can be find here [Community](docs/contracts/Community.md) and here [CommunityERC721](docs/contracts/CommunityERC721.md)   
Most usable method methods will be described below:

<table>
<thead>
	<tr>
		<th>method name</th>
		<th>called by</th>
		<th>description</th>
	</tr>
</thead>
<tbody>
	<tr>
		<td><a href="#addmembers">addMembers</a></td>
		<td>Any role which manage role "members"</td>
		<td>adding new members</td>
	</tr>
	<tr>
		<td><a href="#removemembers">removeMembers</a></td>
		<td>Any role which manage role "members"</td>
		<td>removing exists members</td>
	</tr>
	<tr>
		<td><a href="#grantroles">grantRoles</a></td>
		<td>Any role which manage "roles"</td>
		<td>adding members to new "roles"</td>
	</tr>
	<tr>
		<td><a href="#revokeroles">revokeRoles</a></td>
		<td>Any role which manage "roles"</td>
		<td>removing members from "roles". Revert if any roles can not be managed by sender</td>
	</tr>
	<tr>
		<td><a href="#createrole">createRole</a></td>
		<td>only `owners`</td>
		<td>Creating new role</td>
	</tr>
	<tr>
		<td><a href="#managerole">manageRole</a></td>
		<td>only `owners`</td>
		<td>allow account with "sourceRole" setup "targetRole" to another account with default role("members")</td>
	</tr>
	<tr>
		<td><a href="#getmembers">getMembers</a></td>
		<td>anyone</td>
		<td>Returns all members belong to "role"</td>
	</tr>
	<tr>
		<td><a href="#getroles">getRoles</a></td>
		<td>anyone</td>
		<td>Returns all roles which member belong to</td>
	</tr>
	<tr>
		<td><a href="#membercount">memberCount</a></td>
		<td>anyone</td>
		<td>Returns number of all members belong to "role"</td>
	</tr>
	<tr>
		<td><a href="#inviteprepare">invitePrepare</a></td>
		<td>only "relayers"</td>
		<td>storing signatures of invite</td>
	</tr>
	<tr>
		<td><a href="#inviteaccept">inviteAccept</a></td>
		<td>only "relayers"</td>
		<td>accepting admin's invite</td>
	</tr>
	<tr>
		<td><a href="#inviteview">inviteView</a></td>
		<td>anyone</td>
		<td>Returns tuple of invite stored at contract</td>
	</tr>
</tbody>
</table>

## Methods

#### addMembers
adding new members. Can be called any role which manage role `members`

Params:
name  | type | description
--|--|--
members|address[]| member's addresses

#### removeMembers
removing exists members. Can be called any role which manage role `members`

Params:
name  | type | description
--|--|--
members|address[]| member's addresses 

#### grantRoles
adding members to new `roles`.  Can  be called any role which manage `roles`. Revert if any roles can not be managed by sender

Params:
name  | type | description
--|--|--
members|address[]| member's address    
roles|string[]| names of roles

#### revokeRoles
removing members to new `roles`.  Can  be called any role which manage `roles`. Revert if any roles can not be managed by sender

Params:
name  | type | description
--|--|--
members|address[]| member's address    
roles|string[]| names of roles

#### createRole
Creating new role. Сan called `owners`

Params:
name  | type | description
--|--|--
role|string| name of role

#### manageRole
allow account with `sourceRole` setup `targetRole` to another account with default role(`members`). Сan called only by `owners`.

Params:
name  | type | description
--|--|--
sourceRole|string| name of source role
targetRole|string| name of target role
 
#### getMembers
Returns all members belong to `role`

Params:
name  | type | description
--|--|--
role|string| name of role. [optional] if not specified returned all participants with role `members`

#### getRoles
Returns all roles which member belong to

Params:
name  | type | description
--|--|--
member|address | member's address. [optional] if not specified returned all roles

#### memberCount
Returns number of all members belong to `role`

Params:
name  | type | description
--|--|--
role|string| name of role. [optional] if not specified returned number of all participants with role `members`

#### invitePrepare
Storing signatures of invite

Params:
name  | type | description
--|--|--
pSig|bytes|admin's signature
rpSig|bytes|recipient's signature

#### inviteAccept
Accepting admin's invite

Params:
name  | type | description
--|--|--
p|string|admin's message which will be signed
pSig|bytes|admin's signature
rp|string|recipient's message which will be signed
rpSig|bytes|recipient's signature

#### inviteView
Returns tuple of invite stored at contract

Params:
name  | type | description
--|--|--
pSig|bytes|admin's signature


Return Tuple:
name  | type | description
--|--|--
pSig|bytes|admin's signature
rpSig|bytes|recipient's signature
gasCost|uint256| stored gas which was spent by relayers for invitePrepare(or and inviteAccepted) 
reimbursed|ENUM(0,1,2)|ReimburseStatus (0-NONE,1-PENDING,2-DONE)
used|bool| if true invite is already used
exists|bool|if true invite is exist


## Example to use
1.	add several users to role 'contest-users'
	* owner create new role 'contest-users' by calling method `createRole('contest-users')`
	* owner (or some1 who can call `addMembers`) added users by calling method `addMembers(['<address>'])`
	* owner (or some1 who can manage role 'contest-users') added role to member by calling `addRoles(['<address>'],['contest-users'])`
	* now any1 who want view members of 'contest-users' can call method `getMembers(['contest-users'])` 
2. create sub-admins who can add several users to role 'escrow-users'
	*	owner create new role 'sub-admins' by calling method `createRole('sub-admins')`
	*	owner create new role 'escrow-users' by calling method `createRole('escrow-users')`
	*   owner allow role 'sub-admins' manage role 'escrow-users'  by calling `manageRole('sub-admins','escrow-users')`
	* owner added sub-admin 
		* call `addMembers(['<subadmin address>'])`
		* add role to sub-admin by calling `addRoles(['<subadmin  address>'],['sub-admins'])`
	* now sub-admin can added new escrow users
		* call `addMembers(['<address1>','<address2>','<address3>'])`
		* add role to user by calling `addRoles(['<address1>','<address2>','<address3>'],['escrow-users'])`
	* now any1 who want view members of 'escrow-users' can call method `getMembers(['escrow-users'])` 
3. how view which roles has user
	*	call `getRoles(['<user address>'])`
4. add user via invite (described in [issue](https://github.com/Intercoin/CommunityContract/issues/1))	
	* owner or admin who can add role 
		* generate message with format `<some string data>:<address of communityContract>:<array of rolenames (sep=',')>:<some string data>`. for example `AAAAA:0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC:judges,guests:BBBBBB`
		* sign message with own private key
		* so got message(`p`), messageHash(`pHash`), signature(`pSig`)
		* send `p` and `pSig` to recipeint (and maybe address of communityContract)
	* recipient 
		* generate own message with format `<address of R wallet>:<some string data>`. for example `0x5B38Da6a701c568545dCfcB03FcB875f56beddC4:John Doe`
		* so got message(`rp`), messageHash(`rpHash`), signature(`rpSig`)
		* send `pSig` and `rpSig` to X  (and maybe address of communityContract)
	* X call method invitePrepare(`pSig`,`rpSig`) at communityContract
	* Recipient 
		* check that invite was added in communityContract by calling method inviteView(`pSig`). Signature `rpSig` must match.
		* send `p`,`pSig`,`rp`,`rpSig` to X  (and maybe address of communityContract)
	* X call method inviteAccept(`p`,`pSig`,`rp`,`rpSig`) at communityContract
	* if all ok X will reimburced gas for this two transactions and Recipient will become a roles `judges,guests`
	* also 
		* X will get reward for using system. contract will send `REWARD_AMOUNT` eth. REWARD_AMOUNT is constant 0.001 eth.
		* Recipient will get replenish. contract will send `REPLENISH_AMOUNT` eth. REPLENISH_AMOUNT is constant 0.001 eth.
	
		
