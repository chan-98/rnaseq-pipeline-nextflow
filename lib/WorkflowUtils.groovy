import nextflow.Nextflow
import java.util.UUID
import java.text.SimpleDateFormat
import java.util.Date

class WorkflowUtils {

    public static void initialize(params, log) {
        if(!params.data_remote) {
          Nextflow.error("ERROR: params.data_remote is required for this pipeline. Please add to config and resume")
        }
    }

    public static List<String> generateUUIDs(int numberOfUUIDs) {
        List<String> uuidList = []
        for (int i = 0; i < numberOfUUIDs; i++) {
            UUID uuid = UUID.randomUUID()
            uuidList.add(uuid.toString())
        }
        return uuidList
    }

    public static String getStageDirName() {
        Date currentDate = new Date()
        String desiredDateFormat = "MMM-dd-yyyy"

        SimpleDateFormat formatter = new SimpleDateFormat(desiredDateFormat)
        String formattedDate = formatter.format(currentDate)
        String retVal = "Results-$formattedDate"
        Nextflow.log.warn("WARN:Stage Directory Name: $retVal")
        return retVal
    }

    public static boolean directoryExists(String path) {
        File dir = new File(path);
        return dir.exists() && dir.isDirectory();
    }

}