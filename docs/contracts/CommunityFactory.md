# CommunityFactory

contracts/CommunityFactory.sol

# Overview

Once installed will be use methods:

| **method name** | **called by** | **description** |
|-|-|-|
|<a href="#implementationstate">implementationState</a>|everyone||
|<a href="#implementationview">implementationView</a>|everyone||
|<a href="#instances">instances</a>|everyone||
|<a href="#instancescount">instancesCount</a>|everyone|view amount of created instances|
|<a href="#produce">produce</a>|everyone|creation CommunityERC721 instance|
## *Constructor*




## *Events*
### InstanceCreated

Arguments

| **name** | **type** | **description** |
|-|-|-|
| instance | address | not indexed |
| instancesCount | uint256 | not indexed |



## *StateVariables*
### implementation

> Notice: Community implementation address


| **type** |
|-|
|address|



## *Functions*
### implementationState

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |



### implementationView

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | address |  |



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

Arguments

| **name** | **type** | **description** |
|-|-|-|
| hook | address | address of contract implemented ICommunityHook interface. Can be address(0) |
| name | string | erc721 name |
| symbol | string | erc721 symbol |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| instance | address | address of created instance `CommunityERC721` |


