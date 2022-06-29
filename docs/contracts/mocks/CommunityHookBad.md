# CommunityHookBad

contracts/mocks/CommunityHookBad.sol

# Overview

Once installed will be use methods:

| **method name** | **called by** | **description** |
|-|-|-|
|<a href="#rolecreated">roleCreated</a>|everyone||
|<a href="#rolegranted">roleGranted</a>|everyone||
|<a href="#rolerevoked">roleRevoked</a>|everyone||
|<a href="#set">set</a>|everyone||
|<a href="#supportsinterface">supportsInterface</a>|everyone||
|<a href="#throwincreatedexecuted">throwInCreatedExecuted</a>|everyone||
|<a href="#throwinrevokedexecuted">throwInRevokedExecuted</a>|everyone||
|<a href="#throwinrolegrantedexecuted">throwInRoleGrantedExecuted</a>|everyone||
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



### set

Arguments

| **name** | **type** | **description** |
|-|-|-|
| throwInRoleGrantedExecuted_ | bool |  |
| throwInRevokedExecuted_ | bool |  |
| throwInCreatedExecuted_ | bool |  |



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



### throwInCreatedExecuted

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bool |  |



### throwInRevokedExecuted

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bool |  |



### throwInRoleGrantedExecuted

Outputs

| **name** | **type** | **description** |
|-|-|-|
| -/- | bool |  |


