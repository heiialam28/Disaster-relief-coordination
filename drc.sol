/**
 * @title DisasterReliefCoordination
 * @dev Smart contract for coordinating disaster relief efforts
 * @author Disaster Relief Team
 */
contract DisasterReliefCoordination {
    
    // Struct to represent a disaster event
    struct DisasterEvent {
        uint256 id;
        string location;
        string disasterType;
        uint256 severity; // 1-10 scale
        uint256 timestamp;
        address reportedBy;
        bool isActive;
        uint256 fundsRaised;
        uint256 fundsAllocated;
    }
    
    // Struct to represent a relief resource
    struct ReliefResource {
        uint256 id;
        uint256 disasterId;
        string resourceType; // "medical", "food", "shelter", "transport"
        uint256 quantity;
        string location;
        address provider;
        bool isAvailable;
        uint256 timestamp;
    }
    
    // Struct to represent a relief worker/volunteer
    struct ReliefWorker {
        address workerAddress;
        string name;
        string skills; // "medical", "rescue", "logistics", etc.
        string location;
        bool isAvailable;
        uint256 registrationTime;
        uint256 completedMissions;
    }
    
    // State variables
    address public coordinator;
    uint256 public nextDisasterId;
    uint256 public nextResourceId;
    
    mapping(uint256 => DisasterEvent) public disasters;
    mapping(uint256 => ReliefResource) public resources;
    mapping(address => ReliefWorker) public reliefWorkers;
    mapping(uint256 => address[]) public disasterWorkers; // disaster ID => worker addresses
    
    uint256[] public activeDisasters;
    uint256[] public availableResources;
    
    // Events
    event DisasterReported(uint256 indexed disasterId, string location, string disasterType, uint256 severity);
    event ResourceDonated(uint256 indexed resourceId, uint256 disasterId, string resourceType, uint256 quantity);
    event WorkerAssigned(address indexed worker, uint256 indexed disasterId);
    event FundsReceived(uint256 indexed disasterId, uint256 amount, address donor);
    event FundsAllocated(uint256 indexed disasterId, uint256 amount, string purpose);
    
    // Modifiers
    modifier onlyCoordinator() {
        require(msg.sender == coordinator, "Only coordinator can perform this action");
        _;
    }
    
    modifier validDisaster(uint256 _disasterId) {
        require(_disasterId < nextDisasterId, "Invalid disaster ID");
        require(disasters[_disasterId].isActive, "Disaster is not active");
        _;
    }
    
    constructor() {
        coordinator = msg.sender;
        nextDisasterId = 1;
        nextResourceId = 1;
    }
    
    /**
     * @dev Core Function 1: Report a new disaster event
     * @param _location Location of the disaster
     * @param _disasterType Type of disaster (earthquake, flood, fire, etc.)
     * @param _severity Severity level (1-10)
     */
    function reportDisaster(
        string memory _location,
        string memory _disasterType,
        uint256 _severity
    ) external returns (uint256) {
        require(_severity >= 1 && _severity <= 10, "Severity must be between 1 and 10");
        require(bytes(_location).length > 0, "Location cannot be empty");
        require(bytes(_disasterType).length > 0, "Disaster type cannot be empty");
        
        uint256 disasterId = nextDisasterId;
        
        disasters[disasterId] = DisasterEvent({
            id: disasterId,
            location: _location,
            disasterType: _disasterType,
            severity: _severity,
            timestamp: block.timestamp,
            reportedBy: msg.sender,
            isActive: true,
            fundsRaised: 0,
            fundsAllocated: 0
        });
        
        activeDisasters.push(disasterId);
        nextDisasterId++;
        
        emit DisasterReported(disasterId, _location, _disasterType, _severity);
        return disasterId;
    }
    
    /**
     * @dev Core Function 2: Allocate resources to a disaster
     * @param _disasterId ID of the disaster
     * @param _resourceType Type of resource
     * @param _quantity Quantity of the resource
     * @param _location Current location of the resource
     */
    function allocateResource(
        uint256 _disasterId,
        string memory _resourceType,
        uint256 _quantity,
        string memory _location
    ) external validDisaster(_disasterId) returns (uint256) {
        require(_quantity > 0, "Quantity must be greater than 0");
        require(bytes(_resourceType).length > 0, "Resource type cannot be empty");
        require(bytes(_location).length > 0, "Location cannot be empty");
        
        uint256 resourceId = nextResourceId;
        
        resources[resourceId] = ReliefResource({
            id: resourceId,
            disasterId: _disasterId,
            resourceType: _resourceType,
            quantity: _quantity,
            location: _location,
            provider: msg.sender,
            isAvailable: true,
            timestamp: block.timestamp
        });
        
        availableResources.push(resourceId);
        nextResourceId++;
        
        emit ResourceDonated(resourceId, _disasterId, _resourceType, _quantity);
        return resourceId;
    }
    
    /**
     * @dev Core Function 3: Coordinate relief workers for disaster response
     * @param _name Name of the worker
     * @param _skills Skills of the worker
     * @param _location Current location of the worker
     */
    function registerReliefWorker(
        string memory _name,
        string memory _skills,
        string memory _location
    ) external {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_skills).length > 0, "Skills cannot be empty");
        require(bytes(_location).length > 0, "Location cannot be empty");
        
        reliefWorkers[msg.sender] = ReliefWorker({
            workerAddress: msg.sender,
            name: _name,
            skills: _skills,
            location: _location,
            isAvailable: true,
            registrationTime: block.timestamp,
            completedMissions: 0
        });
    }
    
    /**
     * @dev Assign a relief worker to a disaster
     * @param _worker Address of the relief worker
     * @param _disasterId ID of the disaster
     */
    function assignWorkerToDisaster(
        address _worker,
        uint256 _disasterId
    ) external onlyCoordinator validDisaster(_disasterId) {
        require(reliefWorkers[_worker].workerAddress != address(0), "Worker not registered");
        require(reliefWorkers[_worker].isAvailable, "Worker not available");
        
        disasterWorkers[_disasterId].push(_worker);
        reliefWorkers[_worker].isAvailable = false;
        
        emit WorkerAssigned(_worker, _disasterId);
    }
    
    /**
     * @dev Donate funds to a specific disaster
     * @param _disasterId ID of the disaster to donate to
     */
    function donateFunds(uint256 _disasterId) external payable validDisaster(_disasterId) {
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        disasters[_disasterId].fundsRaised += msg.value;
        
        emit FundsReceived(_disasterId, msg.value, msg.sender);
    }
    
    /**
     * @dev Allocate funds for disaster relief (only coordinator)
     * @param _disasterId ID of the disaster
     * @param _amount Amount to allocate
     * @param _purpose Purpose of the allocation
     */
    function allocateFunds(
        uint256 _disasterId,
        uint256 _amount,
        string memory _purpose
    ) external onlyCoordinator validDisaster(_disasterId) {
        require(_amount > 0, "Amount must be greater than 0");
        require(disasters[_disasterId].fundsRaised >= disasters[_disasterId].fundsAllocated + _amount, 
                "Insufficient funds available");
        
        disasters[_disasterId].fundsAllocated += _amount;
        
        emit FundsAllocated(_disasterId, _amount, _purpose);
    }
    
    /**
     * @dev Complete a relief mission and mark worker as available
     * @param _worker Address of the worker
     */
    function completeMission(address _worker) external onlyCoordinator {
        require(reliefWorkers[_worker].workerAddress != address(0), "Worker not registered");
        require(!reliefWorkers[_worker].isAvailable, "Worker is already available");
        
        reliefWorkers[_worker].isAvailable = true;
        reliefWorkers[_worker].completedMissions++;
    }
    
    /**
     * @dev Close a disaster event
     * @param _disasterId ID of the disaster to close
     */
    function closeDisaster(uint256 _disasterId) external onlyCoordinator {
        require(_disasterId < nextDisasterId, "Invalid disaster ID");
        require(disasters[_disasterId].isActive, "Disaster is already closed");
        
        disasters[_disasterId].isActive = false;
        
        // Remove from active disasters array
        for (uint i = 0; i < activeDisasters.length; i++) {
            if (activeDisasters[i] == _disasterId) {
                activeDisasters[i] = activeDisasters[activeDisasters.length - 1];
                activeDisasters.pop();
                break;
            }
        }
    }
    
    // View functions
    function getActiveDisasters() external view returns (uint256[] memory) {
        return activeDisasters;
    }
    
    function getDisasterWorkers(uint256 _disasterId) external view returns (address[] memory) {
        return disasterWorkers[_disasterId];
    }
    
    function getAvailableResources() external view returns (uint256[] memory) {
        return availableResources;
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
