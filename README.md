# CommunityContract
Smart contract for managing community membership and roles. Also has implemented NFT Interface. 
When role granted to user, user obtained NFT for each role. 
User can customize own NFT and specify ExtraURI    

# Deploy
Any user can create own community by call method produce of CommunityFactory contract: [produce(hook, name, symbol)](docs/contracts/CommunityFactory.md#produce)

# Overview
There are 6 predefined roles:   

role name| role index
--|--
`relayers`|1
`owners`|2
`admins`|3
`members`|4
`alumni`|5
`visitors`|6

Role `relayers` is web servers X which can register new accounts in community via invite by owners/admins or some who can manage.

Roles `owners` is a single role that can magage itself. means one owner can add(or remove) other owner.   
   
Contract can be used as external storage for getting list of members.   

Any user obtain NFT with tokenID = `(roleid <<160)+walletaddress`
Any who can manage certain role can setup tokenURI for this role by calling `setRoleURI`.  
Also any member can setup personal URI for his role by calling `setExtraURI`.   

Full methods for each contracts can be find here [Community](docs/contracts/Community.md)
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
		<td>allow account with "byRole" setup "ofRole" to any another account</td>
	</tr>
	<tr>
		<td><a href="#getaddresses">getAddresses</a></td>
		<td>anyone</td>
		<td>Returns all accounts belong to "role"</td>
	</tr>
	<tr>
		<td><a href="#getroles">getRoles</a></td>
		<td>anyone</td>
		<td>Returns all roles which account belong to</td>
	</tr>
	<tr>
		<td><a href="#addressescount">addressesCount</a></td>
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

#### grantRoles
adding accounts to new `roles`.  Can  be called any role which manage `roles`. Revert if any roles can not be managed by sender

Params:
name  | type | description
--|--|--
accounts|address[]| account's address    
roles|uint8[]| indexes of roles

#### revokeRoles
removing `roles` from certain accounts.  Can  be called any role which manage `roles`. Revert if any roles can not be managed by sender

Params:
name  | type | description
--|--|--
accounts|address[]| accounts's address    
roles|uint8[]| indexes of roles

#### createRole
Creating new role. Сan called by `owners`

Params:
name  | type | description
--|--|--
role|string| name of role

#### manageRole
allow account with `byRole` setup `ofRole` to another account with default role(`members`). Сan called only by `owners`.

Params:
name  | type | description
--|--|--
byRole|uint8| index of source role
ofRole|uint8| index of target role
canGrantRole|bool| if true then `byRole` can grant `ofRole` to account, overwise - disabled
canRevokeRole|bool| if true then `byRole` can revoke `ofRole` from account, overwise - disabled
requireRole|uint8| target account should be in role `requireRole` to be able to obtain `ofRole`. if zero - then available to everyone
maxAddresses|uint256| amount of addresses that be available to grant in `duration` period(bucket) if zero - then no limit
duration|uint64| if zero - then no buckets. but if `maxAddresses` != 0 then it's real total maximum addresses available to grant
 
#### getAddresses
Returns all accounts belong to `role`

Params:
name  | type | description
--|--|--
role|uint8| index of role.

#### getRoles
Returns all roles which member belong to

Params:
name  | type | description
--|--|--
account|address | account's address. [optional] if not specified returned all roles

#### addressesCount
Returns number of all accounts belong to `role`

Params:
name  | type | description
--|--|--
role|uint8| index of role.

#### invitePrepare
Storing signatures of invite

Params:
name  | type | description
--|--|--
sSig|bytes|admin's signature
rSig|bytes|recipient's signature

#### inviteAccept
Accepting admin's invite

Params:
name  | type | description
--|--|--
p|string|admin's message which will be signed
sSig|bytes|admin's signature
rp|string|recipient's message which will be signed
rSig|bytes|recipient's signature

#### inviteView
Returns tuple of invite stored at contract

Params:
name  | type | description
--|--|--
sSig|bytes|admin's signature


Return Tuple:
name  | type | description
--|--|--
sSig|bytes|admin's signature
rSig|bytes|recipient's signature
gasCost|uint256| stored gas which was spent by relayers for invitePrepare(or and inviteAccepted) 
reimbursed|ENUM(0,1,2)|ReimburseStatus (0-NONE,1-PENDING,2-DONE)
used|bool| if true invite is already used
exists|bool|if true invite is exist


## Example to use
visit [wiki](https://github.com/Intercoin/CommunityContract/wiki/Example-to-use)
	
