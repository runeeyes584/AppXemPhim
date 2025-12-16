import express from "express";
import { deleteUser, getAllUser, getUser, updateUser } from "../controllers/User.controller.js";

import { authMiddleware } from "../middleware/authMiddleware.js";

const router = express.Router();

router.get("/", authMiddleware, getAllUser)
router.get("/:id", authMiddleware, getUser)
router.put("/:id", authMiddleware, updateUser)
router.delete("/:id", authMiddleware, deleteUser)

export default router;