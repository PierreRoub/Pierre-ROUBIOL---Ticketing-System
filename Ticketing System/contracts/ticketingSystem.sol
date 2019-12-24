pragma solidity >=0.4.21 <0.6.0;


contract ticketingSystem {

    struct Artist
    {
        bytes32 name;
        address payable owner;
        uint artistCategory;
        uint ticketSold;
        uint moneyCollected;
        uint totalTicketSold;
    }

    struct Venue
    {
        bytes32 name;
        uint capacity;
        uint standardComission;
        address payable owner;
        uint moneyCollected;
    }

    struct Concert
    {
        uint concertDate;
        uint ticketPrice;
        uint totalSoldTicket;
        uint totalMoneyCollected;
        uint artistId;
        uint venueId;
        bool validatedByArtist;
        bool validatedByVenue;
    }

    struct Ticket
    {
    	uint concertId;
    	address payable owner;
        bool isAvailable;
        bool isAvailableForSale;
        uint amountPaid;
        uint ticketId;
    }

    uint concertId=1;
    uint artistId = 1;
    uint venueId =1;
    uint ticketId=1;
    uint oneDay = 60*60*24;
     
    mapping (uint => Artist) public artistsRegister;
    mapping (uint => Venue) public venuesRegister;
    mapping (uint => Concert) public concertsRegister;
    mapping (uint => Ticket) public ticketsRegister;

    function createArtist(bytes32 _name, uint _artistCategory ) public {
        artistsRegister[artistId].name = _name;
        artistsRegister[artistId].artistCategory = _artistCategory;
        artistsRegister[artistId].owner = msg.sender;
        artistId += 1;
    }

    function modifyArtist(uint _artistId,bytes32 _newName, uint _newArtistCategory, address payable _newOwner) public {
        require(msg.sender == artistsRegister[_artistId].owner);

        artistsRegister[_artistId].name = _newName;
        artistsRegister[_artistId].artistCategory = _newArtistCategory;
        artistsRegister[_artistId].owner = _newOwner;
    }
    
    function createVenue(bytes32 _name, uint _capacity, uint _comission) public {
        venuesRegister[venueId].name = _name;
        venuesRegister[venueId].capacity = _capacity;
        venuesRegister[venueId].standardComission = _comission;
        venuesRegister[venueId].owner = msg.sender;
        venueId += 1;
    }

    function modifyVenue(uint _venueId,bytes32 _newVenueName, uint _newVenueCapacity,uint _newVenueComission, address payable _newVenueAddress) public {
        require(msg.sender == venuesRegister[_venueId].owner);

        venuesRegister[_venueId].name = _newVenueName;
        venuesRegister[_venueId].capacity = _newVenueCapacity;
        venuesRegister[_venueId].standardComission = _newVenueComission;
        venuesRegister[_venueId].owner = _newVenueAddress;
    }

    function createConcert(uint _artistId, uint _venueId, uint _concertDate, uint _ticketPrice) public returns (uint concertIdTR) {
        require(_concertDate >= now);
        require(artistsRegister[_artistId].owner != address(0));
        require(venuesRegister[_venueId].owner != address(0));

        concertsRegister[concertId].concertDate = _concertDate;
        concertsRegister[concertId].artistId = _artistId;
        concertsRegister[concertId].venueId = _venueId;
        concertsRegister[concertId].ticketPrice = _ticketPrice;
        concertsRegister[concertId].totalSoldTicket=0;
        concertsRegister[concertId].totalMoneyCollected=0;
        validateConcert(concertId);
        concertIdTR = concertId;
        concertId +=1;
  }
    function validateConcert(uint _concertId) public{
        require(concertsRegister[_concertId].concertDate >= now);

        if (venuesRegister[concertsRegister[_concertId].venueId].owner == msg.sender)
        {
            concertsRegister[_concertId].validatedByVenue = true;
        }
        if (artistsRegister[concertsRegister[_concertId].artistId].owner == msg.sender)
        {
            concertsRegister[_concertId].validatedByArtist = true;
        }
  }

     function emitTicket(uint _concertId, address payable _ticketOwner) public returns (uint ticketIdTR) {
        require(artistsRegister[concertsRegister[_concertId].artistId].owner == msg.sender);

        ticketsRegister[ticketId].owner = _ticketOwner;
        ticketsRegister[ticketId].isAvailable = true;
        concertsRegister[_concertId].totalSoldTicket +=1;
        ticketIdTR=ticketId;
        ticketId +=1;
     }

     function useTicket(uint _ticketId) public{
         require(msg.sender==ticketsRegister[_ticketId].owner);
         require(concertsRegister[ticketsRegister[_ticketId].concertId].concertDate >= now);
         require(concertsRegister[ticketsRegister[_ticketId].concertId].validatedByVenue == true);
         
         ticketsRegister[_ticketId].owner = address(0);
         ticketsRegister[_ticketId].isAvailable=false;
         ticketsRegister[_ticketId].isAvailableForSale = false;
     }

     function buyTicket(uint _concertId) public payable{
         concertsRegister[_concertId].totalSoldTicket += 1;
         concertsRegister[_concertId].totalMoneyCollected= concertsRegister[_concertId].totalSoldTicket * concertsRegister[_concertId].ticketPrice ;
         ticketsRegister[ticketId].concertId=_concertId;
         ticketsRegister[ticketId].amountPaid= concertsRegister[ticketId].ticketPrice;
         ticketsRegister[ticketId].isAvailable=true;
         ticketsRegister[ticketId].owner=msg.sender;
         ticketsRegister[ticketId].isAvailableForSale=false;
         ticketId++;
     }

     function transferTicket(uint _ticketId, address payable _newOwner) public {
         require(msg.sender==ticketsRegister[_ticketId].owner);

         ticketsRegister[_ticketId].owner= _newOwner;
     }

    function cashOutConcert(uint _concertId, address payable _cashOutAddress) public {
        require(concertsRegister[_concertId].concertDate < now);
        require (msg.sender == artistsRegister[concertsRegister[_concertId].artistId].owner);

        uint venueShare = concertsRegister[_concertId].totalMoneyCollected * venuesRegister[concertsRegister[_concertId].venueId].standardComission/10000;
        uint artistShare = concertsRegister[_concertId].totalMoneyCollected - venueShare; 
        _cashOutAddress.transfer(artistShare);
        concertsRegister[_concertId].totalMoneyCollected=0;
        venuesRegister[concertsRegister[_concertId].venueId].owner.transfer(venueShare);
        artistsRegister[concertsRegister[_concertId].artistId].totalTicketSold = artistsRegister[concertsRegister[_concertId].artistId].totalTicketSold + concertsRegister[_concertId].totalSoldTicket;
    }
       
    function offerTicketForSale(uint _ticketId, uint _salePrice) public {
        require(msg.sender == ticketsRegister[_ticketId].owner);
        require(ticketsRegister[_ticketId].isAvailable == true);
        require(ticketsRegister[_ticketId].isAvailableForSale == false);
        
        ticketsRegister[_ticketId].isAvailableForSale = true;
        ticketsRegister[_ticketId].amountPaid=_salePrice;
    }

    function buySecondHandTicket(uint _ticketId) public payable{
        require(ticketsRegister[_ticketId].isAvailableForSale == true);
        require(ticketsRegister[_ticketId].amountPaid == msg.value);

        ticketsRegister[_ticketId].isAvailableForSale == false ;
        ticketsRegister[_ticketId].owner.transfer(msg.value);
        ticketsRegister[_ticketId].owner = msg.sender;
    }
}