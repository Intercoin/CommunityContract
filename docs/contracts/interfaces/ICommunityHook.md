# ICommunityHook

contracts/interfaces/ICommunityHook.sol

> Title: interface represents hook contract that can be called every time when role created/granted/revoked

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

> Details: Returns true if this contract implements the interface defined by `interfaceId`. See the corresponding https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section] to learn more about how these ids are created. This function call must use less than 30 000 gas.

Arguments

| **name** | **type** | **description** |
|-|-|-|
| interfaceId | bytes4 |  |

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bool |  |


