pragma solidity ^0.5.0;

/** 
 * @title fiuba
 * @dev Implements voting process along with vote delegation
 */

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.3.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.3.0/contracts/token/ERC20/ERC20Detailed.sol";

contract Fuc is ERC20, ERC20Detailed {
    constructor() ERC20() ERC20Detailed("FIUBA-COIN", "FUC",18) public {
        _mint(msg.sender, 1000000);
    }
}
 
contract Admin {
    
    address coinAddress;
    Fuc token;
    
    function setCoinAddress(address _coinAddress) external {
        coinAddress = _coinAddress;
        token = Fuc(_coinAddress);
    }
    
     
       
    struct Course {
        uint id;
        string name;
        address professor;
        uint credits;
        uint[] correlatives;
        bool active;
    }
 
    uint CoursesCount;
    Course[] public courses;
    
    struct courseRegistered {
        uint id;
        bool presenceOnly;
        uint approvalDate;
        address student;
    }
    
    courseRegistered[] public studentStates;
    
    event log(string _comment);
    event logCredits(uint);
    
    function getCourseCorrelatives(uint _id) public view returns(uint[] memory) {
        for (uint i = 0; i < CoursesCount; i++) {
            Course storage elem = courses[i];
            if (elem.id == _id) {
                return (elem.correlatives);
            }
        }
    }
    
    function createCourse(uint _id, string memory _name, address _professor, uint _credits, uint[] memory _correlatives, bool _active) public onlyOwner {
        bool push = true;
        for (uint i = 0; i < courses.length; i++) {
            if (courses[i].id == _id) {
                push = false;
            }
        }
        if (push) {
            CoursesCount++;
            courses.push(Course(_id, _name, _professor, _credits, _correlatives, _active));
        } else {
            emit log("There is already a course with this id.");
        }
    }
    
    function modifyCourse(uint _id, string memory _name, address _professor, uint _credits, uint[] memory _correlatives, bool _active) public onlyOwner {
        for (uint i = 0; i < courses.length; i++) {
            if (courses[i].id == _id) {
                courses[i].name = _name;
                courses[i].professor = _professor;
                courses[i].credits = _credits;
                courses[i].correlatives = _correlatives;
                courses[i].active = _active;
            }
        }
    }
    
    function assignCourse(uint _id, address _student) public onlyProfessor(_id) {
        uint[] memory correlatives = getCourseCorrelatives(_id);
        if (correlatives.length == 0) {
            studentStates.push(courseRegistered(_id,false,0, _student));
        } else {
            bool push = true;
            for (uint i = 0; i < correlatives.length; i++) {
                bool hasApprovedCourse = false;
                for (uint j = 0; j < studentStates.length; j++) {
                    if (studentStates[j].id == correlatives[j] && studentStates[j].student == _student && studentStates[j].presenceOnly == false && studentStates[j].approvalDate != 0) {
                        hasApprovedCourse = true;
                    }
                }
                if (!hasApprovedCourse) { 
                    push = false;
                }
            }
            require(push,"The student hasn't approved all the correlatives.");
        }
    }
    
    function approveCourse(uint _id, bool _presenceOnly, address _student) public onlyProfessor(_id) {
        bool registered = false;
        for (uint j = 0; j < studentStates.length; j++) {
            if (studentStates[j].id == _id || studentStates[j].student == _student) {
                studentStates[j].presenceOnly = _presenceOnly;
                studentStates[j].approvalDate = uint(now);
                registered = true;
            }
        }
        require(registered,"The student is not registered in this course.");
        uint credits = 0;
        for (uint i = 0; i < courses.length; i++) {
            if (courses[i].id == _id) {
                credits = courses[i].credits;
            }
        }
        emit logCredits(credits);
        if (_presenceOnly) {
            token.transferFrom(coinAddress,_student,credits/2);
        }
        if (!_presenceOnly) {
            token.transferFrom(coinAddress,_student,credits);
        }
    }
    
    function transfer(address _professor) public onlyCoinOwner {
        token.transfer(_professor,20);
    }
    
    function test() public {
        token.approve(owner, 20);
    }

    function checkState(uint _id) public {
        for (uint i = 0; i < studentStates.length; i++) {
            if (studentStates[i].id == _id && (now - studentStates[i].approvalDate) > 44496000) {
                remove(i);
            }
        }
    }
    
    function remove(uint index) private {
        if (index >= studentStates.length) return;

        for (uint i = index; i<studentStates.length-1; i++){
            studentStates[i] = studentStates[i+1];
        }
        studentStates.length--;
    }

    address owner = msg.sender;

    modifier onlyOwner() {
        require(msg.sender == owner,"Only the owner of the contract can perform this action.");
        _;
    }
    
    modifier onlyProfessor(uint _id) {
        address professor;
        for (uint i = 0; i < courses.length; i++) {
            Course storage elem = courses[i];
            if (elem.id == _id) {
                professor = elem.professor;
            }
        }  
        require(msg.sender == professor,"Only the professor can perform this action.");
        _;
    }
    
    event logAddress(address);
    
    modifier onlyCoinOwner {
        emit logAddress(msg.sender);
        emit logAddress(coinAddress);
        require(msg.sender == coinAddress,"Only the owner of the FUC token can perform this action.");
        _;
    }
  
}
