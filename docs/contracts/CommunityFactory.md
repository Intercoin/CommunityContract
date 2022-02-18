# CommunityFactory

contracts/CommunityFactory.sol

# Overview

Once installed will be use methods:

| **method name** | **called by** | **description** |
|-|-|-|
|<a href="#instances">instances</a>|everyone||
|<a href="#instancescount">instancesCount</a>|everyone|view amount of created instances|
|<a href="#produce">produce</a>|everyone|creation Community instance|
|<a href="#produce">produce</a>|everyone|creation CommunityERC721 instance|
## *Constructor*


Arguments

| **name** | **type** | **description** |
|-|-|-|
| communityImpl | address | address of Community implementation |
| communityerc721Impl | address | address of CommunityERC721 implementation |



## *Events*
### InstanceCreated

Arguments

| **name** | **type** | **description** |
|-|-|-|
| instance | address | not indexed |
| instancesCount | uint256 | not indexed |



## *StateVariables*
### communityImplementation

> Notice: Community implementation address


| **type** |
|-|
|address|



### communityerc721Implementation

> Notice: CommunityERC721 implementation address


| **type** |
|-|
|address|



## *Functions*
### instances

Arguments

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint256 |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |



### instancesCount

> Details: view amount of created instances

Outputs

| **name** | **type** | **description** |
|-|-|-|
| amount | uint256 | amount instances |



### produce

Outputs

| **name** | **type** | **description** |
|-|-|-|
| instance | address | address of created instance `Community` |



### produce

Arguments

| **name** | **type** | **description** |
|-|-|-|
| name | string | erc721 name |
| symbol | string | erc721 symbol |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| instance | address | address of created instance `CommunityERC721` |


