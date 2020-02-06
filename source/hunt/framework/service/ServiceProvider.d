module hunt.framework.service.ServiceProvider;

import poodinis;

/**
 * https://code.tutsplus.com/tutorials/how-to-register-use-laravel-service-providers--cms-28966
 */
abstract class ServiceProvider {

    package(hunt.framework) shared DependencyContainer _container;

    shared(DependencyContainer) container() {
        return _container;
    }

    /**
     * Register any application services.
     *
     * @return void
     */
    void register();


    /**
     * Bootstrap the application events.
     *
     * @return void
     */
    void boot() {}
}