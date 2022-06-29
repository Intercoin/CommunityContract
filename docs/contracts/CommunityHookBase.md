# CommunityHookBase

contracts/CommunityHookBase.sol

# Overview

Once installed will be use methods:

| **method name** | **called by** | **description** |
|-|-|-|
|<a href="#rolecreated">roleCreated</a>|everyone||
|<a href="#rolegranted">roleGranted</a>|everyone||
|<a href="#rolerevoked">roleRevoked</a>|everyone||
|<a href="#supportsinterface">supportsInterface</a>|everyone||
## *Functions*
### roleCreated

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | bytes32 |  |
| roleIndex | uint8 |  |



### roleGranted

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | bytes32 |  |
| roleIndex | uint8 |  |
| account | address |  |



### roleRevoked

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | bytes32 |  |
| roleIndex | uint8 |  |
| account | address |  |



### supportsInterface

> Details: See {IERC165-supportsInterface}.

Arguments

| **name** | **type** | **description** |
|-|-|-|
| interfaceId | bytes4 |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bool |  |


