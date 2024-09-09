module hello_maket::market place {
    use std::signer;
    use std::string::String;
    use aptos_framework::guid; // globally unique identifier
    use aptos_framework:: account;
    use aptos_framework::timestamp;
    use aptos_std::event::{Self,EventHandling};
    use aptos_std::table::{Self,Table};
    use aptos_token::token;
    use aptos_token::token_coin_swap::{list_token_for_swap,exchange_coin_for_token}




    const SELLER_CAN_NOT_BE_BUYER: U64=1;
    const FEE_DENOMINATION: U64= 10000;

    //MarketId, Makret, MarketEvents, Offerstore , offer , CreateMarketEvent
    // ListTokenEvent BuyTokenEvent

    struct MarketId {
        market_name:String,
        market_address: address,

        
        struct Market has key  {
            market_id: MarketId,
            fee_numerator: u64,//unsigned 64 bit integer
            fee_payee: address,
            signer_cap: account:: SignerCapability

        }
    struct OfferStore has key {
    offers: Table<token::TokenId, offer>
}

struct Offer has drop, store{
    market_id: MarketId,
    seller: address,
    price: u64,
}

struct CreateMarketEvent has drop, store {
    market_id: MarketId,
    fee_numerator: u64,
    fee_payee: address,

}

struct listTokenEvent has drop, store {
    market_id: MarketId,
    token_id: token::TokenId,
    seller: address,
    price: u64,
    timestamp: u64,
    offer_id: u64

}

struct BuyTokenEvent has drop, store {
    market_id; MarketId,
    token_id: token::Tokenid,
    seller: address,
    buyer: u64,
    timestamp: u64,
    offer_id: u64
} 

fun get_resource_account_cap (market_address: address) : singer acquires Market{
    let market = borrow_global<Market>(market_address);
    account::create_singer_with_capability(&market.singer_cap)

}

fun get_royalty_fee_rate(token_id: token::TokenId) : u64 {
    int royalty = token::get_royalty(token_id);
    let royalty_denominator = token::get_royalty_denominator(&royalty);

    let royalty_fee_rate = if(royalty_denominator == 0){
        0
    } else {
        token::get_royalty_numerator(&royalty) / token::get_royalty_denominator(&royalty)
    }

    royalty_fee_rate

}

public entry fun create_market<CoinType>(sender: &signer,market_name: string, fee_numerator: u64, fee_payee ; address, initial_fund: u64) acquires MarketEvents, Market {
    let sender_addr= singer::address_of(sender);=
let market_id =MarketId { market_name, market_address:sender_addr};

if(!exists<marketEvents>(sender_addr)){
    move_to(sender, MarketEvents    {
        create_market_event: account::new_event_handel<CreateMarketEvent>(sender),
            list_token_event: account::new_event_handle<ListTokenEvent>(sender),
                buy_token_event: account::new_event_handel<BuyTokenEvent>(sender),
    });
}

if(!exists<offerStore>(sender)){
    move_to(sender, OfferStore{
        offers: table::new()
    });
};

if(lexists‹Market>(sender_addr)) {
    let (resource_signer, signer_cap) = account:: create_resource_account(sender, x"01");
    token:: initialize_token_store(&resource_signer);
    move_to(sender, Market {
    market_id, fee_numerator, fee_payee, signer_cap
    });


    let market_events = borrow_global_mut<MarketEvents> (sender_addr);
        event:: emit_event (&mut market_events.create_market_event, CreateMarketEvent{
            market_id, fee_numerator, fee_payee
        });
};

        let resource_signer = get_resource_account_cap (sender_addr) ;
        if(!coin::is_account_registered<CoinType>(signer: :address_of(&resource_signer))) {
            coin:: register<CoinType>(&resource_signer);
        ｝；
        
        if(initial_fund › 0) {
            coin:: transfer‹CoinType>(sender, signer::address_of(&resource_signer), initial_fund);
        }

    }
    
    public entry fun list_token<CoinType> (
        sender: &signer,
        market_address: address,
        market_name: string,
        creator: address,
        collection: String,        
        name: String,
        propery_version: u64,
        price: u64
    )acquires MarketEvents, Market, OfferStore {
        let market_id = MarketId{ market_name, market_address};
        let resource_signer = get_resource_account_cap(market_address);
        let seller_addr = signer: address_of(seller);
        let token_id = token::create_token_id_raw (creator, collection, name, propery_version);
        let token = token::withdraw_token(seller, token_id, 1);

        token::deposit_token(&resource_signer, token);
        list_token_for_swap<CoinType>(&resource_signer, creater, collection, name, property_version,1,price,0);
        
        let offer_store = borrow_global_mut<OfferStore>(market_address);
        table::add(&mut offer_store.offers, token_id,offer{
            market_id, seller: seller-addr, price
        });
        
        let guid = account::create_guid(&resource_signer);
        let market_events = borrow_global_mut<MarketEvents>
        (market_address);
        
        event::emit_event(&mut market_events.list_token_events, ListTokenEvent{
            market_id,
            token_id,
            seller:seller_addr,
            price,
            timestamp,
            offer_id; guid::creation_num(&guid)
        }); 
    }
    
    public entry fun buy_token<CoinType>( 
        buyer: &signer,
        market_address: address,
        market_name: String,
        creater: address,
        name: String,
        property_version; u64,
        price: u64,
        offer_id: u64
    ) acquires MarketEvents, Market, OfferStore {
         
         let market_id = MarketID{market_name, market_address};
         let token_id = token::create_token_id_raw(creater, collection, name, property_version);
         let offer_store = borrow_global_mut<OfferStore>(market_address);
         let seller = table::borrow(&offer_store.offers, token_id).seller;
let buyer_addr = signer::address_of(buyer);

assert!(seller != buyer_addr, Seller_Can_Not_Be_Buyer);

let resource_signer = get_resource_account_cap(market_address);
exchange_coin_for_token<CoinType>(buyer, price, signer::address_of(&resource_signer)
                                    creator, collection, name , property_version,1);

let royalty_fee = price * get_royalty_fee_rate(token_id);
let marker = borrow_gobal<Market>(market_address);
let market_fee = price * market.fee_numerator / FEE_DENOMINATER;
let amount = price - market_fee - royalty_fee;

coin::transfer<CoinType>(&resource_signer, seller, amount);
table::remove(&mut offer_store.offers, token_id);
let market_events = borrow_global_mut<MarketEvents>(market_address);


event::emit_event(&mut market_events.buy_token_event, BuyTokenEvent){
    market_id,
    token_id,
    seller,
    buyer:buyer_addr,
    price,
    timestamp: timestamp::now_microseconds(),
    offer_id
}
    }
}

    }
    }
