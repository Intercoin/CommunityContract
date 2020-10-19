# CommunityContract
Smart contract for managing community membership and roles


# Deploy
when deploy it is no need to pass parameters in to constructor

# Overview
There are 3 predefined roles:
* `owners`
* `admins`
* `members`

Role `members` is starting role for any new accounts.
Roles `owners` and `admins` can manage `members` and any newly created roles.

Contract can be used as external storage for getting list of memebers.

Once installed will be use methods:

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

#### addRoles
adding members to new `roles`.  Can  be called any role which manage `roles`. Revert if any roles can not be managed by sender
Params:
name  | type | description
--|--|--
members|address[]| member's address    
roles|string[]| names of roles

#### removeRoles
removing members to new `roles`.  Can  be called any role which manage `roles`. Revert if any roles can not be managed by sender
Params:
name  | type | description
--|--|--
members|address[]| member's address    
roles|string[]| names of roles

####   transferOwnership
overrode transferOwnership. New owner will get `owners` role
Params:
name  | type | description
--|--|--
newOwner|address | new owner's address 

#### createRole
Creating new role. Сan called onlyOwner
Params:
name  | type | description
--|--|--
role|string| name of role

#### manageRole
allow account with `sourceRole` setup `targetRole` to another account with default role(`members`). Сan called onlyOwner.
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