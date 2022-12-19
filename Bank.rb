require 'scanf'

class Bank
 def initialize

 end
end

class Db
 def initialize(a_filename="db/accounts",t_filename="db/transactions")
    @accounts=[]
    @transaction=[]
    open(a_filename){
        |file|
        while test = file.gets
            test.block_scanf("%d%s%d%f"){|data| @accounts.push(data)}
        end
        
        system("cls")
        }
    open(t_filename){ 
        |file|
        while test = file.gets
            test.block_scanf("%d%d%d%f"){|data| @transaction.push(data)}
        end
        
     #  system("cls")
    }
 end 
end

class Account
end

Db.new