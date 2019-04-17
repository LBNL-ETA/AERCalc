
package gov.lbl.aercalc.error {
public class DatabaseMigrationError extends Error{
    public function DatabaseMigrationError(message:String, id:int=0) {
        super(message,id);
    }
}
}
