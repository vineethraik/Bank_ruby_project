require 'scanf'
# need to work on non existing db files edge case

#----------------------------------------- utility functions ---------------------------------#


def cls 
    system 'cls'  #change accourding to your system (implimentation of clear screen)
end

def prompt_esc(str="Press enter to go back")
    print str
    str = gets
end

#----------------------------------------- class Account ---------------------------------#

class Account
    attr_accessor :name, :id, :ammount, :pin
    
    def initialize (str="")
        if str.nil?
            @id=0
            @name=0
            @pin=0
            @ammount=0

        else
            temp_data_store=[]
            if(str.block_scanf("%d%s%d%f"){|data| temp_data_store=data }.length == 0)
                raise RangeError.new("invalid data")
            else
                @id=temp_data_store[0]
                @name=temp_data_store[1]
                @pin=temp_data_store[2]
                @ammount=temp_data_store[3]
            end
        end

    end
end

#----------------------------------------- class Transaction ---------------------------------#

class Transaction
    attr_accessor  :id, :from, :to, :ammount

    def initialize (str="")
        if str.nil?
            @id=0
            @from=0
            @to=0
            @ammount=0

        else
            temp_data_store=[]
            if(str.block_scanf("%d%d%d%f"){|data| temp_data_store=data }.length == 0)
                raise RangeError.new("invalid data")
            else
                @id=temp_data_store[0]
                @from=temp_data_store[1]
                @to=temp_data_store[2]
                @ammount=temp_data_store[3]
            end
        end

    end
end

#----------------------------------------- class Db ---------------------------------#

class Db
    
 def initialize(a_filename="db/accounts",t_filename="db/transactions")
    temp1=a_filename.split('/')
    temp2=t_filename.split('/')
    temp1.delete_at(-1)
    temp2.delete_at(-1)
    dir1=temp1.join('/')
    dir2=temp2.join('/')
    if(!File.exists?(dir1))
        Dir.mkdir dir1
    end

    if(!File.exists?(dir2))
        Dir.mkdir dir2
    end

    if(!File.exists?(a_filename))
        file=File.open(a_filename,'w')
        file.close
    end
    if(!File.exists?(t_filename))
        file=File.open(t_filename,'w')
        file.close
    end
    @account_file_name=a_filename
    @transaction_file_name = t_filename
    @accounts=[]
    @transactions=[]
    self.refresh
 end
 

 def refresh
    @accounts=[]
    @transactions=[]
   open(@account_file_name){
       |file|
       
       while data = file.gets
        if data.strip.length != 0
            @accounts.push(Account.new(data.strip))    
        end
       end
   }
   open(@transaction_file_name){
       |file|
       while data = file.gets
        if data.strip.length != 0
            @transactions.push(Transaction.new(data.strip))
        end
       end
   }
 end

 def write_to_disk
    File.write(@account_file_name,@accounts.map{|ac| "#{ac.id} #{ac.name} #{ac.pin} #{ac.ammount}"}.join("\n")) 
    File.write(@transaction_file_name,@transactions.map{|ac| "#{ac.id} #{ac.from} #{ac.to} #{ac.ammount}"}.join("\n")) 
 end

 def get_name_by_id(id)
    @accounts.select{|ac| ac.id==id}[0].name
 end

 def get_balence_by_id(id)
    @accounts.select{|ac| ac.id==id}[0].ammount
 end

 def get_accounts
   @accounts
 end

 def get_transactions(id = -1)
    if(id == -1)
        @transactions
    else
        @transactions.select{|ac| (ac.from == id || ac.to == id)}.sort{|a, b| a.id <=> b.id}
    end
   
 end

 def add_account (id,name,pin,ammount)
    temp_account = Account.new(nil)
    temp_account.id=id
    temp_account.name=name
    temp_account.pin=pin
    temp_account.ammount=ammount
    @accounts.push(temp_account)
    self.write_to_disk
 end

 def add_transaction (id,from,to,ammount)
    temp_transaction = Transaction.new(nil)
    temp_transaction.id=id
    temp_transaction.from=from
    temp_transaction.to=to
    temp_transaction.ammount=ammount
    @transactions.push(temp_transaction)
    self.write_to_disk
 end

 def add_fund(id,ammount)
    @accounts.select{|ac| ac.id==id}[0].ammount+=ammount
    self.write_to_disk
    return :success
 end

 def remove_fund(id,ammount)
    if(@accounts.select{|ac| ac.id==id}[0].ammount<ammount)
        return :low_balence
    else
        @accounts.select{|ac| ac.id==id}[0].ammount-=ammount
        self.write_to_disk
        return :success
    end
 end
end

#----------------------------------------- class Bank ---------------------------------#
class Bank
 def initialize
    @db =Db.new  
    @current_user_id = -1
 end

 def auth(id,pin)
    admin_id = 'admin'
    admin_pin = 'password'
    

    if (((id<=>admin_id )== 0)&&((pin<=>admin_pin) == 0))
        return :admin
    elsif ((id.to_i == 0) || (id.to_i == 0))
        return :invalid 
    elsif((@db.get_accounts.map{|ac| ac.id}.index(id.to_i))==(@db.get_accounts.map{|ac| ac.pin}.index(pin.to_i)))
        @current_user_id=id.to_i
        return :authorized
    else
        return :unauthorized
    end
 end

 def transact(from_id,to_id,ammount)
    if(ammount<=0)
        return :invalid_ammount
    end
    if(@db.get_accounts.select{|a| a.id==from_id}[0].ammount>=ammount)
        @db.get_accounts.select{|a| a.id==from_id}[0].ammount-=ammount
        @db.get_accounts.select{|a| a.id==to_id}[0].ammount+=ammount
        n=0
        if(@db.get_transactions.length == 0)
            n=1
            
        else
            n = @db.get_transactions.sort{|a,b| a.id<=>b.id}[-1].id + 1
        end
       
       @db.add_transaction(n,from_id,to_id,ammount)
       @db.refresh
       return :success
    else
        return :low_balence
    end
 end

 def add_remove_fund(params)
    if(params[:ammount]<=0)
        return :invalid_ammount
    end
    if(params[:operation]==1)
       return @db.add_fund(params[:id],params[:ammount])
    else
       return @db.remove_fund(params[:id],params[:ammount])
    end
 end

 def add_account(name,pin,ammount)
    n=1
    if(!@db.get_accounts.length == 0)
        n = @db.get_accounts.sort{|a,b| a.id<=>b.id}[-1].id + 1
    end
    @db.add_account(n,name,pin,ammount)
    @db.refresh
    return n
 end

 def portal
    l1 = false
    while true
        if (l1) then break; end
        cls
        puts '1.auth'
        puts '2.exit'
        puts 'enter your choice'
        n=gets
    
        if (n=~/1/)
            tries = 0
            l2=false
            while true
                if (l1||l2) then break; end
                tries+=1
                cls
                puts 'Enter your customer id'
                id = gets.strip
               
                puts 'Enter your Pin'
                pin = gets.strip
                
                case self.auth(id,pin)
                when :authorized
                    l3=false
                    while true
                        if (l1||l2||l3) then break; end
                        cls
                        puts "hello #{@db.get_name_by_id(@current_user_id)}"
                        puts "1.transact"
                        puts "2.transactions"
                        puts "3.check balence"
                        puts "4.logout"
                        print "Enter choice:"
                        n=gets
                        if(n=~/1/)
                            cls
                            puts "Chose your resipent"
                            @db.get_accounts.select{|a| a.id!=@current_user_id}.each{
                                |acc|
                                puts "#{acc.id} #{acc.name}"
                            }
                            n=gets.to_i
                            puts "enter your ammount"
                            amt = gets.to_f
                            puts "Enter your pin"
                            pin = gets.to_i

                            case self.auth(@current_user_id,pin)
                            when :authorized
                                case self.transact(@current_user_id,n,amt)
                                when :success
                                    puts "Transaction was succussfull"
                                    puts "Your balence is: #{@db.get_balence_by_id(@current_user_id)}"
                                    prompt_esc

                                when :low_balence
                                    puts "Your balence is low for your transaction"
                                    prompt_esc

                                when :invalid_ammount
                                    puts "Invalid ammount"
                                    prompt_esc
                                else
                                    puts "unknown error"
                                    sleep(1)
                                end
                            else
                                @current_user_id=-1
                                l2=true
                            end
                        elsif(n=~/2/)
                            cls
                            print "Enter your pin:"
                            pin = gets
                            case self.auth(@current_user_id.to_s,pin)
                            when :authorized
                                cls
                                puts "your transactions"
                                @db.get_transactions(@current_user_id).each{
                                    |trx|
                                    if(trx.from==@current_user_id)
                                        puts "You sent #{@db.get_name_by_id(trx.to)} #{trx.ammount} Rupies"
                                    else
                                        puts "#{@db.get_name_by_id(trx.from)} sent You #{trx.ammount} Rupies"
                                    end
                                }
                                prompt_esc

                            else
                                @current_user_id=-1
                                l2=true
                            end
                        elsif(n=~/3/)
                            cls
                            print "Enter your pin:"
                            pin = gets

                            case self.auth(@current_user_id.to_s,pin)
                            when :authorized
                                cls
                                puts "your balence ammout is: #{@db.get_balence_by_id(@current_user_id)}"
                                prompt_esc
                                
                            else
                                l2=true
                                next
                            end

                        elsif(n=~/4/)
                            @current_user_id=-1
                            l2=true
                            next
                        else
                            puts "wrong choice"
                            sleep(1)
                        end
                    end
                when :unauthorized
                    if tries>=3
                        counter = 30
                        while counter>0
                            cls
                            puts "try again after #{counter} seconds"
                            sleep(1)
                            counter-=1
                        end
                        tries=0
                    else
                        cls
                        puts 'try again'
                        sleep(1)
                    end
                    
                when :admin
                    l3 =false
                    while true
                        if (l1||l2||l3) then break; end
                        cls
                        puts 'Hello Admin'
                        puts "1.add account"
                        puts "2.get all report"
                        puts "3.add/remove fund"
                        puts "4.logout"
                        n=gets

                        if(n=~/1/)
                            cls 
                            print "Enter name of account holder:"
                            name = gets.strip
                            print "Enter pin for account:"
                            pin = gets.to_i
                            print "Enter account openeing balence:"
                            ammount = gets.to_f
                            puts "name: #{name}, Pin: #{pin}, Ammount: #{ammount}"
                            print "do you want to continue (y/n)? "
                            prompt = gets.strip
                            if((prompt<=>'y')==0)
                                cls
                                puts "enter your password"
                                pass = gets.strip
                                case self.auth('admin',pass)
                                when :admin
                                    num = self.add_account(name,pin,ammount)
                                    case num
                                    when :filed
                                    else
                                        cls 
                                        puts "Account created"
                                        ac = @db.get_accounts.select{|ac| ac.id==num}[0]
                                        puts "id: #{ac.id}, name: #{ac.name}, pin: #{ac.pin}, balence: #{ac.ammount},"
                                        prompt_esc
                                    end
                                else
                                    cls 
                                    l2=true
                                end
                            else
                                cls
                            end
                        elsif(n=~/2/)
                            cls 
                            puts "enter your password"
                            pass=gets.strip
                            case self.auth('admin',pass)
                            when :admin
                                puts "Accounts"
                                @db.get_accounts.each{
                                    |ac|
                                    puts "ID: #{ac.id}, Customer: #{ac.name}, Balence:#{ac.ammount}"
                                }

                                puts "\nTransactions"
                                @db.get_transactions.each{
                                    |trx|
                                    puts "ID: #{trx.id}, From: #{@db.get_name_by_id(trx.from)}, To: #{@db.get_name_by_id(trx.to)}, Ammount:#{trx.ammount}\n"
                                }
                                prompt_esc
                            else
                                l2=true
                                next
                            end
                        elsif(n=~/3/)
                            cls
                            puts "select customer to modify"
                            if(@db.get_accounts.length==0)
                                cls
                                puts "No accounts present"
                                prompt_esc
                                next
                            end
                            @db.get_accounts.each{
                                |ac|
                                puts "#{ac.id}.#{ac.name}"
                            }
                            id = gets.to_i
                            puts "1.add fund"
                            puts "2.remove fund"
                            choise = gets.to_i
                            puts "Enter ammount"
                            ammount=gets.to_i
                            puts "Enter password"
                            pass = gets.strip
                            case self.auth('admin',pass)
                            when :admin
                                case self.add_remove_fund(id: id ,operation: choise,ammount: ammount)
                                when :success
                                    cls
                                    puts "Transaction succusfull"
                                    prompt_esc
                                when :low_balence
                                    cls
                                    puts "Transaction failed due to low balence"
                                    prompt_esc
                                when :invalid_ammount
                                    cls
                                    puts "Transaction failed due to invalid ammount"
                                    prompt_esc
                                else
                                    cls
                                    puts "Transaction status unknown"
                                    prompt_esc
                                end
                            else
                                l2=true
                                next
                            end
                        elsif(n=~/4/)
                            l2=true
                            next
                        else
                        end
                    end
                when :invalid
                    puts "Invalid credentials, please put valid id and pin"
                    prompt_esc("Press enter to try again")
                else
                    puts 'unknown'
                    l2=true
                    sleep(1)
                    next
                end
            end
        elsif(n=~/2/)
            return true
        else
            puts 'wrong choice'
            sleep(1)
        end
    end
 end
end

#----------------------------------------- class End ---------------------------------#
# Bank.new 

#  db=Db.new   
#  puts "starts\n"  
#  sleep(10)
#  puts "ends\n" 
#  db.write_to_disk



# temp=Account.new("1 vineeth 1452 120.00")
# temp1=Transaction.new("1 1 2 100")
# print temp1.ammount = 290
# print temp1.ammount
 

# def test
#     open("test/tempfile.txt"){|file|
#     file.each{|str| print str}
#     File.write("test/tempfile.txt","sdafsgdhfgj\n")
# }
# end

# testq
   
Bank.new.portal
