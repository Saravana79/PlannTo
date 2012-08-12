class MobilesController < ProductsController
  def index
    puts "ppppppppppppppppppp #{(User.join_follows.followable_type('Car') - User.friends(User.find(33)))}"
  end
end
