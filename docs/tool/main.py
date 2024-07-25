### This function delares macros which can be used in the documentation files.

def define_env(env):

    @env.macro
    def price():
        return "Hi"