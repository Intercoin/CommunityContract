# CommunityHook

contracts/mocks/CommunityHook.sol

# Overview

Once installed will be use methods:

| **method name** | **called by** | **description** |
|-|-|-|
|<a href="#rolecreated">roleCreated</a>|everyone||
|<a href="#rolecreatedexecuted">roleCreatedExecuted</a>|everyone||
|<a href="#rolegranted">roleGranted</a>|everyone||
|<a href="#rolegrantedexecuted">roleGrantedExecuted</a>|everyone||
|<a href="#rolerevoked">roleRevoked</a>|everyone||
|<a href="#rolerevokedexecuted">roleRevokedExecuted</a>|everyone||
|<a href="#supportsinterface">supportsInterface</a>|everyone||
## *Functions*
### roleCreated

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | bytes32 |  |
| roleIndex | uint8 |  |



### roleCreatedExecuted

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint256 |  |



### roleGranted

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | bytes32 |  |
| roleIndex | uint8 |  |
| account | address |  |



### roleGrantedExecuted

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint256 |  |



### roleRevoked

Arguments

| **name** | **type** | **description** |
|-|-|-|
| role | bytes32 |  |
| roleIndex | uint8 |  |
| account | address |  |



### roleRevokedExecuted

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | uint256 |  |



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


