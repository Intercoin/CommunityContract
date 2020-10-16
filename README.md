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

#### addMember
adding new member. Can be called any role which manage role `members`
Params:
name  | type | description
--|--|--
member|address | member's address

#### removeMember
removing exists member. Can be called any role which manage role `members`
Params:
name  | type | description
--|--|--
member|address | member's address    

#### addMemberRole
adding member to new `roleName`.  Can  be called any role which manage role `roleName`
Params:
name  | type | description
--|--|--
member|address | member's address    
roleName|string | name of role

#### removeMemberRole
removing member to new `roleName`.  Can be called any role which manage role `roleName`
Params:
name  | type | description
--|--|--
member|address | member's address    
roleName|string | name of role

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
roleName|string| name of role

#### manageRole
allow account with `sourceRole` setup `targetRole` to another account with default role(`members`). Сan called onlyOwner.
Params:
name  | type | description
--|--|--
sourceRole|string| name of source role
targetRole|string| name of target role
 
#### getMembers
Returns all members belong to `roleName`
Params:
name  | type | description
--|--|--
roleName|string| name of role

#### getRoles
Returns all roles which member belong to
Params:
name  | type | description
--|--|--
member|address | member's address

## Example to use
1.	add several users to role 'contest-users'
	* owner create new role 'contest-users' by calling method `createRole('contest-users')`
	* owner (or some1 who can call `addMember`) added users by calling method `addMember('<address>')`
	* owner (or some1 who can manage role 'contest-users') added role to member by calling `addMemberRole('<address>','contest-users')`
	* now any1 who want view members of 'contest-users' can call method `getMembers('contest-users')` 
2. create sub-admins who can add several users to role 'escrow-users'
	*	owner create new role 'sub-admins' by calling method `createRole('sub-admins')`
	*	owner create new role 'escrow-users' by calling method `createRole('escrow-users')`
	*   owner allow role 'sub-admins' manage role 'escrow-users'  by calling `manageRole('sub-admins','escrow-users')`
	* owner added sub-admin 
		* call `addMember('<subadmin address>')`
		* add role to sub-admin by calling `addMemberRole('<subadmin  address>','sub-admins')`
	* now sub-admin can added new escrow users
		* call `addMember('<address>')`
		* add role to user by calling `addMemberRole('<address>','escrow-users')`
	* now any1 who want view members of 'escrow-users' can call method `getMembers('escrow-users')` 
3. how view which roles has user
	*	call `getRoles('<user address>')`