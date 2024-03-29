#' Train a machine learning model to classify images
#'
#' \code{train} allows users to train their own machine learning model using images
#' that have been manually classified. We recommend having at least 2,000 images per species,
#' but accuracies will be higher with > 10,000 images. This model will take a very long
#' time to run. We recommend using a GPU if possible. In the \code{data_info} csv, you must
#' have two columns with NO HEADERS. Column 1 must be the file name of the image. Column 2
#' must be a number corresponding to the species. Give each species (or group of species) a
#' number identifying it. The first species must be 0, the next species 1, and so on. If this is your first time using
#' this function, you should see additional documentation at https://github.com/mikeyEcology/MLWIC .
#' This function uses absolute paths, but if you are unfamilliar with this
#' process, you can put all of your images, the image label csv ("data_info") and the L1 folder that you
#' downloaded following the directions at https://github.com/mikeyEcology/MLWIC into one directory on
#' your computer. Then set your working directory to this location and the function will find the
#' absolute paths for you.
#'
#' @param path_prefix Absolute path to location of the images on your computer
#' @param data_info csv with file names for each photo (absolute path to file). This file must have no headers (column names).
#'  column 1 must be the file name of each image including the extention (i.e., .jpg). Column 2
#'  must be a number corresponding to the species. Give each species (or group of species) a
#'  number identifying it. The first species must be 0, the next species 1, and so on.
#' @param python_loc The location of python on your machine.
#' @param num_gpus The number of GPUs available. If you are using a CPU, leave this as default.
#' @param num_classes The number of classes (species or groups of species) in your model.
#' @param delimiter this will be a `,` for a csv.
#' @param model_dir Absolute path to the location where you stored the L1 folder
#'  that you downloaded from github.
#' @param os the operating system you are using. If you are using windows, set this to
#'  "Windows", otherwise leave as default
#' @param architecture the architecture of the deep neural network (DNN). Resnet-18 is the default.
#'  Other options are c("alexnet", "densenet", "googlenet", "nin", "vgg")
#' @param depth the number of layers in the DNN. If you are using resnet, the options are c(18, 34, 50, 101, 152).
#'  If you are using densenet, the options are c(121, 161, 169, 201).
#'  If you are an architecture other than resnet or densenet, the number of layers will be automatically set.
#' @param log_dir_train directory where you will store the model information.
#'  This will be called when you what you specify in the \code{log_dir} option of the
#'  \code{classify} function. You will want to use unique names if you are training
#'  multiple models on your computer; otherwise they will be over-written.
#' @param batch_size the number of images simultaneously passed to the model for training.
#'  It must be a multiple of 64. Smaller numbers will train models that are more accurate, but it will
#'  take longer to train. The default is 128.
#' @param retrain If TRUE, the model you train will be a retraining of the model presented in
#'  the Tabak et al. MEE paper. If FALSE, you are starting training from scratch. Retraining will be faster
#'  but training from scratch will be more flexible.
#' @param print_cmd print the system command instead of running the function. This is for development.
#' @export
train <- function(
  # set up some parameters for function
  path_prefix = paste0(getwd(), "/images"), # absolute path to location of the images on your computer
  data_info = paste0(getwd(), "/image_labels.csv"), # csv with file names for each photo. See details
  model_dir = getwd(),
  python_loc = "/anaconda2/bin/",
  os="Mac",
  num_gpus = 2,
  num_classes = 28, # number of classes in model
  delimiter = ",", # this will be , for a csv.
  architecture = "resnet",
  depth = "18",
  batch_size = "128",
  log_dir_train = "train_output",
  retrain = TRUE,
  print_cmd = FALSE
) {

  wd1 <- getwd() # the starting working directory

  # set these parameters before changing directory
  path_prefix = path_prefix
  data_info = data_info
  model_dir = model_dir

  # navigate to directory with trained model
  if(endsWith(model_dir, "/")){
    setwd(paste0(model_dir, "L1"))
  } else {
    setwd(paste0(model_dir, "/L1"))
  }
  wd <- getwd()

  # load in data_info and store it in the model_dir
  # labels <- utils::read.csv(data_info, header=FALSE)
  # utils::write.csv(labels, "data_info_train.csv", row.names=FALSE)

  if(os=="Windows"){
    # deal with windows file format issues
    data_file <- read.table(data_info, header=FALSE, sep=",")
    output.file <- file("data_info_train.csv", "wb")
    write.table(data_file,
                file = output.file,
                append = TRUE,
                quote = FALSE,
                row.names = FALSE,
                col.names = FALSE,
                sep = ",")
    close(output.file)
    rm(output.file)
  } else {
    cpfile <- paste0("cp ", data_info, " ", wd, "/data_info_train.csv")
    system(cpfile)
  }


  # set depth
  if(architecture == "alexnet"){
    depth <- 8
  }
  if(architecture == "nin"){
    depth <- 16
  }
  if(architecture == "vgg"){
    depth <- 22
  }
  if(architecture == "googlenet"){
    depth <- 32
  }

  # run function
  if(retrain){
    train_py <- paste0(python_loc,
                       "python train.py --architecture ", architecture,
                       " --depth ", depth,
                       " --path_prefix ", path_prefix,
                       " --num_gpus ", num_gpus,
                       " --batch_size ", batch_size,
                       " --data_info data_info_train.csv",
                       " --delimiter ", delimiter,
                       " --retrain_from USDA182 --num_classes ", num_classes,
                       " --log_dir ", log_dir_train)
  }else {
    train_py <- paste0(python_loc,
                       "python train.py --architecture ", architecture,
                       " --depth ", depth,
                       " --path_prefix ", path_prefix,
                       " --num_gpus ", num_gpus,
                       " --batch_size ", batch_size,
                       " --data_info data_info_train.csv",
                       " --delimiter ", delimiter,
                       " --num_classes ", num_classes,
                       " --log_dir ", log_dir_train)
  }


  # printing only?
  if(print_cmd){
    print(train_py)
  } else {
    # run code
    toc <- Sys.time()
    system(train_py)
    tic <- Sys.time()
    runtime <- difftime(tic, toc, units="auto")

    # end function
    txt <- paste0("training of model took ", runtime, " ", units(runtime),  ". ",
                  "The trained model is in ", log_dir_train, ". ",
                  "Specify this directory as the log_dir when you use classify(). ")
    print(txt)
  }

}

#train(model_dir="~/Desktop", print_cmd=TRUE)
