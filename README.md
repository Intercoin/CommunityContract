# CommunityContract
This repository contains the Community Contract, a smart contract that manages roles and permissions within a community.

## The list of basic features:

- The owner can create roles and manage roles and permissions for other roles.
- When a role is granted to a user, the user obtains an NFT for each role.
- Supports the protocol of Native Meta Transactions (ERC-2771).
- Supports the ownable interface from the OpenZeppelin library, accessible to any user in the "owners" role.
- Uses the standard for representing ownership of non-fungible tokens (ERC-721) with small changes:
- - Every person who has a role also has an NFT that represents belonging to this role. Such an NFT cannot be transferred or burnt. However, when an admin revokes a role from the user, the NFT also disappears.

## Installation
You can clone the repository from GitHub:
```bash
git clone git@github.com:Intercoin/CommunityContract.git
```
or install it using npm:
```bash
npm i @artman325/community
```

# Deploy
Any user can create their own community by calling the produce method of the CommunityFactory contract: [produce(hook, invitedHook, name, symbol)](docs/contracts/CommunityFactory.md#produce).    

Link for the factory below

## Factory's addresses depend of networks

# Overview
There are 6 predefined roles:   

role name| role index
--|--
`owners`|1
`admins`|2
`members`|3
`alumni`|4
`visitors`|5

The owners role is a single role that can manage itself, meaning one owner can add or remove other owners.

The contract can be used as external storage for getting a list of members.

Any user obtains an NFT with tokenID = (roleid << 160) + walletaddress.   
Anyone who can manage a certain role can set up the tokenURI for this role by calling setRoleURI.    

Full methods for each contract can be found here: Community. The most usable methods will be described below:


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
</tbody>
</table>

## Methods

#### grantRoles
Adds accounts to new roles. Can be called by any role that manages roles. Reverts if any roles cannot be managed by the sender.

Params:
name  | type | description
--|--|--
accounts|address[]| account's address    
roles|uint8[]| indexes of roles

#### revokeRoles
Removes roles from certain accounts. Can be called by any role that manages roles. Reverts if any roles cannot be managed by the sender.

Params:
name  | type | description
--|--|--
accounts|address[]| accounts's address    
roles|uint8[]| indexes of roles

#### createRole
Creates a new role. Can only be called by owners.

Params:
name  | type | description
--|--|--
role|string| name of role

#### manageRole
Allows an account with byRole to set up ofRole for another account with the default role (members). Can only be called by owners.

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
Returns all accounts belonging to a role.

Params:
name  | type | description
--|--|--
role|uint8| index of role.

#### getRoles
Returns all roles that a member belongs to.

Params:
name  | type | description
--|--|--
account|address | account's address. [optional] if not specified returned all roles

#### addressesCount
Returns the number of all accounts belonging to a role.

Params:
name  | type | description
--|--|--
role|uint8| index of role.


## Example to use
visit [wiki](https://github.com/Intercoin/CommunityContract/wiki/Example-to-use)
	
## License

[MIT](https://choosealicense.com/licenses/mit/)

