<?php
class Unit {
    private $conn;
    private $table_name = "unit_assets";

    public $id;
    public $supported_by;
    public $customer;
    public $location;
    public $branch;
    public $serial_number;
    public $unit_type;
    public $year;
    public $status;
    public $delivery;
    public $jenis_unit;
    public $note;
    public $created_at;
    public $updated_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    // Method untuk read units by branch
    public function readByBranch($branch) {
        $query = "SELECT * FROM " . $this->table_name . " WHERE branch = :branch ORDER BY serial_number";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':branch', $branch);
        $stmt->execute();
        
        return $stmt;
    }

    // Method lainnya yang sudah ada...
    public function read() {
        $query = "SELECT * FROM " . $this->table_name . " ORDER BY serial_number";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }
}
?>