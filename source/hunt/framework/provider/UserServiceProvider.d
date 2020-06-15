module hunt.framework.provider.UserServiceProvider;


import hunt.framework.provider.ServiceProvider;
import hunt.framework.auth.DefaultUserService;
import hunt.framework.auth.UserService;

import hunt.logging.ConsoleLogger;
import poodinis;


/**
 * 
 */
class UserServiceProvider : ServiceProvider {
    
    override void register() {
        container.register!(UserService, DefaultUserService).singleInstance();
    }
}