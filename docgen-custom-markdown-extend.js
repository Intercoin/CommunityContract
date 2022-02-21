module.exports = function dataExtend() {
    return {
        
        'contracts/Community.sol': {
            'description': [
                'Smart contract for managing community membership and roles.',
                ''
            ].join("<br>"),
            'exclude': [
                'getIntercoinAddress',
                //'DEFAULT_OWNERS_ROLE', 'DEFAULT_ADMINS_ROLE', 'DEFAULT_MEMBERS_ROLE', 'DEFAULT_RELAYERS_ROLE', '',
                // 'ADMIN_ROLE', 'DEFAULT_ADMIN_ROLE', 'REDEEM_ROLE', 'CIRCULATION_ROLE', 'CIRCULATION_DEFAULT', 
                // 'authorizeOperator',
                // 'decimals',
                // 'defaultOperators',
                // 'tokensReceived',
                // 'supportsInterface',
                
                
            ],
            'fix': {
            }
        },
        'contracts/CommunityERC721.sol': {
            'description': [
                'Extend Community Smart contract. Each role it\'s ERC721 token, URI can be set by user who can manage. Also any user who belong to role can set ExtraURI ',
                ''
            ].join("<br>"),
            'exclude': [
                'getIntercoinAddress',
                //'DEFAULT_OWNERS_ROLE', 'DEFAULT_ADMINS_ROLE', 'DEFAULT_MEMBERS_ROLE', 'DEFAULT_RELAYERS_ROLE', '',
                // 'ADMIN_ROLE', 'DEFAULT_ADMIN_ROLE', 'REDEEM_ROLE', 'CIRCULATION_ROLE', 'CIRCULATION_DEFAULT', 
                // 'authorizeOperator',
                // 'decimals',
                // 'defaultOperators',
                // 'tokensReceived',
                // 'supportsInterface',
                
                
            ],
            'fix': {
        //         'allowance': {'custom:shortd': 'part of ERC20'},
        //         'approve': {'custom:shortd': 'part of ERC20'},
        //         'balanceOf': {'custom:shortd': 'part of ERC777'},
            }
        }
    };
}
