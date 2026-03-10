<?php
class User {
    private $conn;
    private $table_name = "data_user";

    public $id;
    public $name;
    public $nrpp;
    public $password;
    public $status_user;
    public $branch;
    public $created_at;
    public $updated_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    // Method untuk login
    public function login($nrpp, $password) {
        try {
            $query = "SELECT id, name, nrpp, password, status_user, branch 
                      FROM " . $this->table_name . " 
                      WHERE nrpp = :nrpp 
                      LIMIT 1";

            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':nrpp', $nrpp);
            $stmt->execute();

            if ($stmt->rowCount() > 0) {
                $row = $stmt->fetch(PDO::FETCH_ASSOC);
                
                // Verify password (plain text comparison sesuai dengan login.php)
                if ($row['password'] === $password) {
                    $this->id = $row['id'];
                    $this->name = $row['name'];
                    $this->nrpp = $row['nrpp'];
                    $this->status_user = $row['status_user'];
                    $this->branch = $row['branch'];
                    return true;
                }
            }
            return false;
        } catch (PDOException $exception) {
            throw new Exception("Database error: " . $exception->getMessage());
        }
    }

    // Method untuk get user by NRPP
    public function getByNRPP($nrpp) {
        try {
            $query = "SELECT id, name, nrpp, status_user, branch 
                      FROM " . $this->table_name . " 
                      WHERE nrpp = :nrpp 
                      LIMIT 1";

            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':nrpp', $nrpp);
            $stmt->execute();

            if ($stmt->rowCount() > 0) {
                $row = $stmt->fetch(PDO::FETCH_ASSOC);
                $this->id = $row['id'];
                $this->name = $row['name'];
                $this->nrpp = $row['nrpp'];
                $this->status_user = $row['status_user'];
                $this->branch = $row['branch'];
                return true;
            }
            return false;
        } catch (PDOException $exception) {
            throw new Exception("Database error: " . $exception->getMessage());
        }
    }

    // Method untuk get partners by branch
    public function getPartnersByBranch($branch, $exclude = '') {
        try {
            $query = "SELECT id, name, nrpp, status_user, branch 
                      FROM " . $this->table_name . " 
                      WHERE branch = :branch 
                      AND (status_user LIKE '%FIELD SERVICE%' 
                           OR status_user LIKE '%FMC%' 
                           OR status_user LIKE '%KOORDINATOR%')";

            // Exclude current user jika provided
            if (!empty($exclude)) {
                $query .= " AND name != :exclude";
            }

            $query .= " ORDER BY name";

            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':branch', $branch);
            
            if (!empty($exclude)) {
                $stmt->bindParam(':exclude', $exclude);
            }
            
            $stmt->execute();

            return $stmt;
        } catch (PDOException $exception) {
            throw new Exception("Database error: " . $exception->getMessage());
        }
    }

    // Method untuk get all users
    public function readAll() {
        try {
            $query = "SELECT id, name, nrpp, status_user, branch 
                      FROM " . $this->table_name . " 
                      ORDER BY name";

            $stmt = $this->conn->prepare($query);
            $stmt->execute();

            return $stmt;
        } catch (PDOException $exception) {
            throw new Exception("Database error: " . $exception->getMessage());
        }
    }

    // Method untuk get users by branch
    public function readByBranch($branch) {
        try {
            $query = "SELECT id, name, nrpp, status_user, branch 
                      FROM " . $this->table_name . " 
                      WHERE branch = :branch 
                      ORDER BY name";

            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':branch', $branch);
            $stmt->execute();

            return $stmt;
        } catch (PDOException $exception) {
            throw new Exception("Database error: " . $exception->getMessage());
        }
    }

    // Method untuk create user
    public function create() {
        try {
            $query = "INSERT INTO " . $this->table_name . " 
                      (name, nrpp, password, status_user, branch) 
                      VALUES 
                      (:name, :nrpp, :password, :status_user, :branch)";

            $stmt = $this->conn->prepare($query);

            // Sanitize data
            $this->name = htmlspecialchars(strip_tags($this->name));
            $this->nrpp = htmlspecialchars(strip_tags($this->nrpp));
            $this->password = htmlspecialchars(strip_tags($this->password));
            $this->status_user = htmlspecialchars(strip_tags($this->status_user));
            $this->branch = htmlspecialchars(strip_tags($this->branch));

            // Bind parameters
            $stmt->bindParam(':name', $this->name);
            $stmt->bindParam(':nrpp', $this->nrpp);
            $stmt->bindParam(':password', $this->password);
            $stmt->bindParam(':status_user', $this->status_user);
            $stmt->bindParam(':branch', $this->branch);

            if ($stmt->execute()) {
                $this->id = $this->conn->lastInsertId();
                return true;
            }
            return false;
        } catch (PDOException $exception) {
            throw new Exception("Database error: " . $exception->getMessage());
        }
    }

    // Method untuk update user
    public function update() {
        try {
            $query = "UPDATE " . $this->table_name . " 
                      SET name = :name, 
                          nrpp = :nrpp, 
                          status_user = :status_user, 
                          branch = :branch 
                      WHERE id = :id";

            $stmt = $this->conn->prepare($query);

            // Sanitize data
            $this->name = htmlspecialchars(strip_tags($this->name));
            $this->nrpp = htmlspecialchars(strip_tags($this->nrpp));
            $this->status_user = htmlspecialchars(strip_tags($this->status_user));
            $this->branch = htmlspecialchars(strip_tags($this->branch));

            // Bind parameters
            $stmt->bindParam(':name', $this->name);
            $stmt->bindParam(':nrpp', $this->nrpp);
            $stmt->bindParam(':status_user', $this->status_user);
            $stmt->bindParam(':branch', $this->branch);
            $stmt->bindParam(':id', $this->id);

            return $stmt->execute();
        } catch (PDOException $exception) {
            throw new Exception("Database error: " . $exception->getMessage());
        }
    }

    // Method untuk delete user
    public function delete() {
        try {
            $query = "DELETE FROM " . $this->table_name . " WHERE id = :id";
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':id', $this->id);
            return $stmt->execute();
        } catch (PDOException $exception) {
            throw new Exception("Database error: " . $exception->getMessage());
        }
    }

    // Method untuk check if NRPP exists
    public function nrppExists($nrpp) {
        try {
            $query = "SELECT id FROM " . $this->table_name . " WHERE nrpp = :nrpp";
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':nrpp', $nrpp);
            $stmt->execute();
            return $stmt->rowCount() > 0;
        } catch (PDOException $exception) {
            throw new Exception("Database error: " . $exception->getMessage());
        }
    }

    // Method untuk change password
    public function changePassword($newPassword) {
        try {
            $query = "UPDATE " . $this->table_name . " 
                      SET password = :password 
                      WHERE id = :id";

            $stmt = $this->conn->prepare($query);
            
            $newPassword = htmlspecialchars(strip_tags($newPassword));
            $stmt->bindParam(':password', $newPassword);
            $stmt->bindParam(':id', $this->id);

            return $stmt->execute();
        } catch (PDOException $exception) {
            throw new Exception("Database error: " . $exception->getMessage());
        }
    }
}
?>