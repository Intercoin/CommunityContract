const fs = require('fs');
module.exports = {
    // wrapping deploy contact and wait 1 block, to bu sure that transction successfully mined and not pending!!
    wrapDeploy: async (ident, obj, depl, options) => {
        if (typeof(options) === 'undefined') {
            options = {};
        }
        console.log('starting to deploy "'+ident+'"');    
        var contract;
        if (options.params) {
            contract = await obj.connect(depl).deploy(...options.params);    
        } else {
            contract = await obj.connect(depl).deploy();    
        }
        
        console.log('Waiting for confirmed');
        let rc = await contract.deploymentTransaction().wait(3);

        if (rc.status != 1) {
            throw('deployment failed');
        }
        console.log('mined successfully');
        return contract;
    },
    // get data stored in ./scripts/arguments.json
    get_data: (_message) => {
        return new Promise(function(resolve, reject) {
            fs.readFile('./scripts/arguments.json', (err, data) => {
                if (err) {
                    
                    if (err.code == 'ENOENT' && err.syscall == 'open' && err.errno == -4058) {
                        fs.writeFile('./scripts/arguments.json', "", (err2) => {
                            if (err2) throw err2;
                            resolve();
                        });
                        data = ""
                    } else {
                        throw err;
                    }
                }
        
                resolve(data);
            });
        });
    },
    // store data stored into ./scripts/arguments.json
    write_data: (_message) => {
        return new Promise(function(resolve, reject) {
            fs.writeFile('./scripts/arguments.json', _message, (err) => {
                if (err) throw err;
                console.log('Data written to file');
                resolve();
            });
        });
    }
//   sayHello: () => {
//     console.log('hello');
//   }
}
/*
export async function wrapDeploy(ident, obj, depl, params) {
    console.log('starting to deploy "'+ident+'"');    
    let impl = await obj.connect(depl).deploy();    
    console.log('Waiting for confirmed');
    let rc = await impl.deploymentTransaction().wait(1);
    if (rc.status != 1) {
        throw('deployment failed');
        
    }
console.log('return impl;');
    return impl;
    }

export function sayHello() {
    console.log('hello');
}
*/